
require "sinatra"
require "sinatra/reloader" if development?
require "tilt"

before do
  @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
 
  erb :home
  # File.read "test.html"
  # File.read "public/template.html"
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]
  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")
  erb :chapter
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>)) # why need % here??
  end
end

not_found do
  redirect "/"
end


get "/search" do
  if params[:query]
    @results = @contents.each_with_index.each_with_object([]) do | (chapter, index), results |
      text = File.read("data/chp#{index + 1}.txt")
      paragraphs = text.split("\n\n")
       paragraphs.each_with_index do |paragraph, paragraph_index|
        if paragraph.include?(params[:query])
          results << [chapter, index, paragraph, paragraph_index]
        end
      end
    end
  end
  erb :search
end