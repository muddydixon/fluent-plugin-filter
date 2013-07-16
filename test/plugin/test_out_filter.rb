# -*- coding: utf-8 -*-
require 'helper'

class Filter < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    all allow
    deny status: 404
  ]

  def create_driver(conf = CONFIG, tag='test.input')
    Fluent::Test::OutputTestDriver.new(Fluent::FilterOutput, tag).configure(conf)
  end

  def test_configure
    # add tag
    d = create_driver %[
      all deny
      allow status: 200
      add_prefix hoge
    ]
    assert_equal "hoge", d.instance.add_prefix
    assert_equal [['status', 200]], d.instance.allows
    assert_equal [], d.instance.denies

    # int value
    d = create_driver %[
      all deny
      allow status: 200
    ]
    assert_equal [['status', 200]], d.instance.allows
    assert_equal [], d.instance.denies

    # float value
    d = create_driver %[
      all deny
      allow status: 200.0
    ]
    assert_equal [['status', 200.0]], d.instance.allows
    assert_equal [], d.instance.denies

    # text value
    d = create_driver %[
      all deny
      allow status: "200"
    ]
    assert_equal [['status', '200']], d.instance.allows
    assert_equal [], d.instance.denies

    # text value
    d = create_driver %[
      all deny
      allow status: "https://my.website.com/"
    ]
    assert_equal [['status', 'https://my.website.com/']], d.instance.allows
    assert_equal [], d.instance.denies

    # regexp value
    d = create_driver %[
      all deny
      allow url: /hoge/
    ]
    assert_equal [['url', /hoge/]], d.instance.allows
    assert_equal [], d.instance.denies
    
  end
  def test_emit
    data = [
      {'status' => 200, 'agent' => 'IE'},
      {'status' => 303, 'agent' => 'Gecko'},
      {'status' => 200, 'agent' => 'IE'},
      {'status' => 401, 'agent' => 'Gecko'},
      {'status' => 200, 'agent' => 'Gecka'},
      {'status' => 404, 'agent' => 'Gecko'},
    ]

    d = create_driver(CONFIG, 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 5, d.emits.length

    d = create_driver(%[
      all deny
      allow status: 200
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 3, d.emits.length

    d = create_driver(%[
      all deny
      allow status: 200, status: 303
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 4, d.emits.length

    d = create_driver(%[
      all deny
      allow agent: Gecko
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 3, d.emits.length

    d = create_driver(%[
      all deny
      allow agent: "Gecko"
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 3, d.emits.length

    d = create_driver(%[
      all deny
      allow agent: "Gecko"
      deny status: 200
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 3, d.emits.length

    d = create_driver(%[
      all deny
      allow agent: /Geck/
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal 4, d.emits.length

    d = create_driver(%[
      all deny
      allow agent: /Geck/
      add_prefix hoge
    ], 'test.input')
    d.run do
      data.each do |dat|
        d.emit dat
      end
    end
    assert_equal "hoge.test.input", d.emits[0][0]

  end
end
