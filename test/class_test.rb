require 'test_helper'

class ClassTest < BaseTest

  class RepresentingSong
    attr_reader :name

    def from_hash(doc, *args)
      @name = doc["__name__"]

      self # DISCUSS: do we wanna be able to return whatever we want here? this is a trick to replace the actual object
    end
  end


  describe "class: ClassName, only" do
    representer! do
      property :song, :class => RepresentingSong # supposed this class exposes #from_hash itself.
    end

    it "creates fresh instance and doesn't extend" do
      song = representer.prepare(OpenStruct.new).from_hash({"song" => {"__name__" => "Captured"}}).song
      song.must_be_instance_of RepresentingSong
      song.name.must_equal "Captured"
    end
  end


  describe "class: lambda, only" do
    representer! do
      property :song, :class => lambda { |*| RepresentingSong }
    end

    it "creates fresh instance and doesn't extend" do
      song = representer.prepare(OpenStruct.new).from_hash({"song" => {"__name__" => "Captured"}}).song
      song.must_be_instance_of RepresentingSong
      song.name.must_equal "Captured"
    end
  end


  describe "lambda receiving fragment" do
    let (:klass) { Class.new do

      def self.args=(args)
        @@args = args

        puts self.inspect
        return self
      end
      def self.args
        @@args
      end

      def from_hash(*)
        self.class.new
      end
    end }
    representer!(:inject => :klass) do
      _klass = klass
      property :song, :class => lambda { |fragment, args| _klass.args=([fragment,args]); _klass }
    end

    it { representer.prepare(OpenStruct.new).from_hash({"song" => {"name" => "Captured"}}, :volume => true).song.class.args.
      must_equal([{"name"=>"Captured"}, {:volume=>true}]) }
  end


  describe "class: implementing #from_hash" do
    let(:parser) do
      Class.new do
        def from_hash(*)
          [1,2,3,4]
        end
      end
    end

    representer!(:inject => :parser) do
      property :song, :class => parser # supposed this class exposes #from_hash itself.
    end

    it "allows returning arbitrary objects in #from_hash" do
      representer.prepare(OpenStruct.new).from_hash({"song" => 1}).song.must_equal [1,2,3,4]
    end
  end
end

#TODO: test fragment,

# `class: Song` only, no :extend.
