# -*- coding: utf-8 -*-
require 'helper'

class TestFilterFilter < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    all allow
    deny status: 404
  ]

  def create_driver(conf = CONFIG, tag='test.input')
    Fluent::Test::FilterTestDriver.new(Fluent::FilterFilter, tag).configure(conf)
  end

  data("int value" => [{"allows" => [['status', 200]], "denies" => []},
    %[
      all deny
      allow status: 200
    ]],
       "float value" => [{"allows" => [['status', 200.0]], "denies" => []},
    %[
      all deny
      allow status: 200.0
    ]],
      "text value" => [{"allows" => [['status', '200']], "denies" => []},
    %[
      all deny
      allow status: '200'
    ]],
      "text value with URL" =>
      [{"allows" => [['status', 'https://my.website.com/']], "denies" => []},
    %[
      all deny
      allow status: "https://my.website.com/"
    ]],
      "regexp value with forward slashes" =>
      [{"allows" => [['url', Regexp.new("\\/users\\/\\d+")]], "denies" => []},
    %[
      all deny
      allow url: /\\/users\\/\\d+/
    ]],
      "test values" =>
      [{"allows" => [['message', 'CRIT'], ['message', 'WARN']], "denies" => []},
    %[
      all deny
      allow message: 'CRIT', message: 'WARN'
    ]],
      "test values with comma" =>
      [{"allows" => [['message', 'CRIT,'], ['message', 'WARN']], "denies" => []},
    %[
      all deny
      allow message: 'CRIT,' % message: 'WARN'
      delim %
    ]],
      )
  def test_configure(data)
    expected, target = data
    d = create_driver target
    assert_equal expected["allows"], d.instance.allows
    assert_equal expected["denies"], d.instance.denies
  end

  data("config" => [5, CONFIG],
       "allow status 200" => [3,
    %[
      all deny
      allow status: 200
    ]],
       "allow status 200 and 303" => [4,
    %[
      all deny
      allow status: 200, status: 303
    ]],
       "allow Gecko agent" => [3,
    %[
      all deny
      allow agent: Gecko
    ]],
       "allow \"Gecko\" agent" => [3,
    %[
      all deny
      allow agent: "Gecko"
    ]],
       "allow /Geck/ Regexp matched agent" => [4,
    %[
      all deny
      allow agent: /Geck/
    ]],
       "allow /\\/users\\/\\d+/ Regexp matched path" => [3,
    %[
      all deny
      allow path: /\\/users\\/\\d+/
    ]])
  def test_filter(data)
    expected, target = data
    inputs = [
      {'status' => 200, 'agent' => 'IE', 'path' => '/users/1'},
      {'status' => 303, 'agent' => 'Gecko'},
      {'status' => 200, 'agent' => 'IE', 'path' => '/users/2'},
      {'status' => 401, 'agent' => 'Gecko'},
      {'status' => 200, 'agent' => 'Gecka', 'path' => '/users/3'},
      {'status' => 404, 'agent' => 'Gecko', 'path' => '/wrong'},
    ]
    d = create_driver(target, 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal expected, d.filtered_as_array.length
  end

  data("allow message2" => [1,
     %[
       all deny
       allow message2: /hoge2/
     ]],
       "deny message2" => [1,
     %[
       all allow
       deny message2: /hoge2/
     ]])
  def test_filter_message(data)
    expected, target = data
    inputs = [
      {'message' => 'hoge', 'message2' => 'hoge2'},
      {'message' => 'hoge3'},
    ]
    d = create_driver(target, 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal expected, d.filtered_as_array.length
  end
end
