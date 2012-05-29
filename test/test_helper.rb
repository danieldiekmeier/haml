if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start
end

require 'rubygems'
gem "minitest"
require 'bundler/setup'
require 'test/unit' # On JRuby, tests won't run unless we include this. WTF?
require 'minitest/autorun'
require 'action_pack'
require 'action_controller'
require 'action_view'

require 'rails'
class TestApp < Rails::Application
  config.root = ""
end
Rails.application = TestApp

ActionController::Base.logger = Logger.new(nil)

require 'fileutils'
require 'haml'
require 'haml/template'

Haml::Template.options[:ugly]   = false
Haml::Template.options[:format] = :xhtml

module Declarative
  def test(name, &block)
    define_method("test #{name}", &block)
  end
end

class MiniTest::Unit::TestCase

  extend Declarative

  def render(text, options = {}, &block)
    scope  = options.delete(:scope)  || Object.new
    locals = options.delete(:locals) || {}
    Haml::Engine.new(text, options).to_html(scope, locals, &block)
  end

  def assert_warning(message)
    the_real_stderr, $stderr = $stderr, StringIO.new
    yield

    if message.is_a?(Regexp)
      assert_match message, $stderr.string.strip
    else
      assert_equal message.strip, $stderr.string.strip
    end
  ensure
    $stderr = the_real_stderr
  end

  def silence_warnings(&block)
    Haml::Util.silence_warnings(&block)
  end

  def rails_form_opener
    '<div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>'
  end

  def assert_raises_message(klass, message)
    yield
  rescue Exception => e
    assert_instance_of(klass, e)
    assert_equal(message, e.message)
  else
    flunk "Expected exception #{klass}, none raised"
  end

  def assert_raises_line(line)
    yield
  rescue Sass::SyntaxError => e
    assert_equal(line, e.sass_line)
  else
    flunk "Expected exception on line #{line}, none raised"
  end
end
