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
    ]])
  def test_configure(data)
    expected, target = data
    d = create_driver target
    assert_equal expected["allows"], d.instance.allows
    assert_equal expected["denies"], d.instance.denies
  end

  def test_filter
    inputs = [
      {'status' => 200, 'agent' => 'IE', 'path' => '/users/1'},
      {'status' => 303, 'agent' => 'Gecko'},
      {'status' => 200, 'agent' => 'IE', 'path' => '/users/2'},
      {'status' => 401, 'agent' => 'Gecko'},
      {'status' => 200, 'agent' => 'Gecka', 'path' => '/users/3'},
      {'status' => 404, 'agent' => 'Gecko', 'path' => '/wrong'},
    ]

    d = create_driver(CONFIG, 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 5, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow status: 200
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 3, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow status: 200, status: 303
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 4, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow agent: Gecko
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 3, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow agent: "Gecko"
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 3, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow agent: "Gecko"
      deny status: 200
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 3, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow agent: /Geck/
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 4, d.filtered_as_array.length

    d = create_driver(%[
      all deny
      allow agent: /Geck/
    ], 'test.input')
    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal "test.input", d.filtered_as_array[0][0]

    d = create_driver(%[
      all deny
      allow path: /\\/users\\/\\d+/
    ], 'test.input')

    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 3, d.filtered_as_array.length

    inputs = [
      {'message' => 'hoge', 'message2' => 'hoge2'},
      {'message' => 'hoge3'},
    ]

    d = create_driver(%[
      all deny
      allow message2: /hoge2/
    ], 'test.input')

    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 1, d.filtered_as_array.length

    d = create_driver(%[
      all allow
      deny message2: /hoge2/
    ], 'test.input')

    d.run do
      inputs.each do |dat|
        d.filter dat
      end
    end
    assert_equal 1, d.filtered_as_array.length

  end
end
