require_relative "haml2phlex/version"

module Haml2phlex

class HamlLine
	attr_accessor :level
	attr_accessor :classes
	attr_accessor :tag
	attr_accessor :children
	attr_accessor :parent
	attr_accessor :spacer
	attr_accessor :id

	attr_accessor :origin
	attr_accessor :line
	attr_accessor :code_string
	attr_accessor :attribute_string

	CONTROL_CHARACTERS = " \.\#\%\=\{" #dont put - in here

	def pop_line_until_cc
		x = ""
		while self.line[0] and  not CONTROL_CHARACTERS.include? self.line[0]
			x += self.line.slice! 0 
		end
		return x
	end

	def initialize(line, spacer: "\t")
		#need better seperation of concerns for the line. Currently this method is too messy and it leads to weird errors.
		#perhaps a popping method at the beginning for the classes and ids. And then a popping / if then system for the rest of it.
		#so continually pop the beginning classes/ids, and then if its a { parse the attributes, then if its a = or - the rest is code
		#otherwise if you pop a ' ' then assume the rest is a string (put into a '' and then set as code_string.)

		self.level = 0
		self.classes = []
		self.id = nil
		self.tag = nil
		self.children = []
		self.line = line
		self.origin = line
		self.spacer = spacer
		self.attribute_string = nil
		self.code_string = nil

		while self.line.length > 0 and self.line[0...spacer.length] == spacer
			self.line = self.line.sub spacer, ''
			self.level += 1
		end
		self.line = self.line.strip

		while c = self.line.slice!(0)
			if c == ' '
				self.code_string = "%Q{#{self.line.strip}}"
				break
			elsif c == '{'
				self.line = '{' + self.line
				parse_attributes
				self.line = self.line.sub(self.attribute_string, '')
				nil
			elsif c == '=' or c == '-'
				self.code_string = self.line.strip
				break
			elsif c == '.'
				classes << pop_line_until_cc
			elsif c == '%'
				self.tag = pop_line_until_cc
			elsif c == '#'
				self.id = pop_line_until_cc
			else
				self.code_string = "%Q{#{self.line.strip}}"
				break
			end
		end
		if classes.any? or not id.nil?
			self.tag ||= 'div'
		end
	end

	def parse_attributes
		self.attribute_string = HamlLine.attribute_parser(self.line)
	end

	def matcher(match_char)
		self.class.matcher(self.line, match_char)
	end

	def self.matcher(string, match_char)
		string.scan(/#{match_char}(.*?)(?=[\.\%\=\{\#\ ]|$)/).flatten
	end

	def self.attribute_parser(string)
		if i = string.index('{')
			string = string[(i)...]
			x = 0
			i = 0
			while i < string.length
				if string[i] == '{'
					x += 1
				elsif string[i] == '}'
					x -= 1
					if x == 0
						break
					end
				end
				i += 1
			end
			string = string[0...(i+1)]
			return string
		else
			return nil
		end
	end

	def find_spot_for_other_node(x)
		if self.level == (x.level - 1)
			self.children << x
			x.parent = self
			return self
		elsif self.parent.nil?
			return nil
		else
			return self.parent.find_spot_for_other_node(x)
		end
	end

	def out()
		space = self.spacer * self.level
		if self.tag.nil?
			if self.children.any?
				return %Q{
#{space}#{self.code_string}#{self.children.map{|c|c.out}.join('')}
#{space}end}
			else
				return %Q{
#{space}#{self.code_string}}
			end
		end
		o = ''
		att = {}

		#check for the haml classes / ids
		if self.id
			att[:id] = self.id
		end
		if self.classes.any?
			att[:class] = self.classes.join(' ')
		end

		if self.attribute_string.nil? and not att.keys.any?
			att = ''
		else
			#figure out how we gonna handle attributes
			if self.attribute_string.nil?
				att = att.to_s[1...-1]
			elsif not att.keys.any?
				att = self.attribute_string[1...-1] #so without the outermost {}
			else
				
				if att[:class] or att[:id]
					if (att[:class] and self.attribute_string.include?('class')) or (att[:id] and self.attribute_string.include?('id'))
						#seems like there is a conflict, do not merge
						o << %Q{
#{space}#{att}   # ❌🤦❌🤦❌🤦❌🤦❌🤦❌🤦❌🤦❌ MERGE THESE INTO THE NEXT LINE 🔻🔻🔻🔻🔻🔻🔻}
					else
						self.attribute_string[-1] = ', ' + att.to_s[1...] #we can merge as it doesn't seem like there are any conflicts
					end
				end

				att = self.attribute_string[1...-1]
			end
		end
		if self.children.any?
			o << %Q{
#{space}#{tag}(#{att}) {#{self.children.map{|c|c.out}.join('')}
#{space}}}
		elsif not self.code_string.nil?
			o << %Q{
#{space}#{tag}(#{att}) { #{code_string} } }
		else
			o << %Q{
#{space}#{tag}(#{att})}
		end
		return o
	end
end

class Haml2phlex
	attr_accessor :lines
	attr_accessor :hlines
	attr_accessor :filename
	attr_accessor :base_root

	def initialize(filename, spacer: "\t", base_root: "app/views/")
		self.filename = filename
		filename = "#{base_root}#{filename}"
		self.base_root = base_root
		f = File.open(filename, 'r')
		txt = f.read

		self.lines = txt.split "\n"
		self.hlines = []

		last = nil
		#process into a more usable format
		for line in lines
			next if line.strip == ''
			x = HamlLine.new(line, spacer: spacer)
			if last.nil?
				hlines << x
			else
				out = last.find_spot_for_other_node(x)
				if out.nil?
					hlines << x
				end
			end
			last = x
		end
		return self.hlines
	end
	def out
		self.hlines.map{|hl| hl.out}.join('')
	end
	def spit
		x = self.filename.split('/')
		x[-1] = x[-1].split('.')[0]

		if x[-1][0] == '_'
			x[-1][0] = ''
		end
		
		#rb_path = self.base_root + '/' + x.join('/')
		
		rb_fname = x.join '/'

		rb_class = rb_fname.camelcase
		
		rb_fname = self.base_root +  rb_fname + ".rb"
		
		f = File.open(rb_fname, 'w+')
		f.write %Q{
module Views
	class #{rb_class} < Phlex::HTML
		include ApplicationView

		def initialize(**args)
			#sets whatever you put in as a instance variable
			for k in args.keys
				self.instance_variable_set("@\#{k}", args[k])
			end
		end

		def template(&)
			base_page(&)
		end

		def base_page(&)
			#{out}
		end
	end
end}
		f.close
		puts 'written to ' + rb_fname
	end
end
end
