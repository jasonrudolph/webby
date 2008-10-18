
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::Helpers::UrlHelper do
  include Webby::Helpers::TagHelper
  include Webby::Helpers::UrlHelper

  # -----------------------------------------------------------------------
  describe 'link_to' do
    it 'should render a simple link with no attributes' do
      link = link_to('Google', 'http://www.google.com/')
      link.should == %Q{<a href="http://www.google.com/">Google</a>}
    end

    it 'should render a link with an anchor' do
      link = link_to('Google', 'http://www.google.com', :anchor => 'blah')
      link.should == %Q{<a href="http://www.google.com#blah">Google</a>}
    end
    
    it 'should render a link with attributes' do
      link = link_to('Google', 'http://www.google.com/', :attrs => {:name => 'google', :title => 'searchy searchy'})
  
      link.should match(/<a .+>Google<\/a>/)
      link.should include('href="http://www.google.com/"')
      link.should include('name="google"')
      link.should include('title="searchy searchy"')
    end

    it 'should render a link to a page' do
      Webby::Resources.stub!(:find_layout)
      @filename = File.join %w[content tumblog rss.txt]
      @page = Webby::Resources::Page.new(@filename)

      link = link_to('Subscribe via RSS', @page)
      link.should == %Q{<a href="/tumblog/rss.xml">Subscribe via RSS</a>}
    end
    
    it "should render JavaScript 'back' link" do
      link = link_to('Good Ole Days', :back)
      link.should == %Q{<a href="javascript:history.back()">Good Ole Days</a>}
    end
  end
  
end

# EOF
