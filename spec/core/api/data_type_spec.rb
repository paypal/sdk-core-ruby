require 'spec_helper'

describe PayPal::SDK::Core::API::DataTypes::Base do

  DataType = PayPal::SDK::Core::API::DataTypes::Base

  class TestCurrency < DataType

    # Members
    object_of :amount, String
    object_of :desciption, String, :namespace => "ns"
    # Attributes
    add_attribute :currencyID, :namespace => "cc"
  end

  class TestType < DataType
    object_of :fromCurrency, TestCurrency
    array_of  :toCurrency,   TestCurrency
    object_of :firstname,    String, :name => "first-name"
  end

  class TestSimpleType < DataType
    include PayPal::SDK::Core::API::DataTypes::SimpleTypes
    object_of :created_on, Date
    object_of :created_at, DateTime
  end

  class Message < DataType
    object_of :value, String
  end

  it "should allow content key" do
    message = Message.new("Testing message")
    message.value.should eql "Testing message"

    message = Message.new(:value => "Testing message")
    message.value.should eql "Testing message"
  end

  it "should create member object automatically" do
    test_type = TestType.new
    test_type.fromCurrency.should   be_a TestCurrency
    test_type.toCurrency.should     be_a Array
    test_type.toCurrency[0].should  be_a TestCurrency
    test_type.toCurrency[1].should  be_a TestCurrency
    test_type.toCurrency[0].amount.should eql nil
    test_type.fromCurrency.amount.should  eql nil
    test_type.fromCurrency.desciption.should    eql nil
    test_type.fromCurrency.currencyID.should    eql nil
  end

  it "should convert the given data to configured type" do
    test_type = TestType.new( :fromCurrency => { :currencyID => "USD", :amount => "50.0"})
    test_type.fromCurrency.should be_a TestCurrency
    test_type.fromCurrency.currencyID.should    eql "USD"
    test_type.fromCurrency.amount.should  eql "50.0"
  end

  it "should allow block with initializer" do
    test_type = TestType.new do
      fromCurrency do
        self.currencyID = "USD"
        self.amount = "50.0"
      end
    end
    test_type.fromCurrency.currencyID.should    eql "USD"
    test_type.fromCurrency.amount.should  eql "50.0"
  end

  it "should allow block with member" do
    test_type = TestType.new
    test_type.fromCurrency do
      self.currencyID = "USD"
      self.amount = "50.0"
    end
    test_type.fromCurrency.currencyID.should    eql "USD"
    test_type.fromCurrency.amount.should  eql "50.0"
  end

  it "should assign value to attribute" do
    test_currency = TestCurrency.new( :@currencyID => "USD", :amount => "50" )
    test_currency.currencyID.should eql "USD"
  end

  it "should allow configured Class object" do
    test_currency = TestCurrency.new( :currencyID => "USD", :amount => "50" )
    test_type = TestType.new( :fromCurrency => test_currency )
    test_type.fromCurrency.should eql test_currency
  end

  it "should allow snakecase" do
    test_type = TestType.new( :from_currency => {} )
    test_type.from_currency.should be_a TestCurrency
    test_type.from_currency.should eql test_type.fromCurrency
  end

  it "should allow array" do
    test_type = TestType.new( :toCurrency => [{ :currencyID => "USD", :amount => "50.0" }] )
    test_type.toCurrency.should be_a Array
    test_type.toCurrency.first.should be_a TestCurrency
    test_type.toCurrency.first.currencyID.should eql "USD"
  end

  it "should skip undefind members on initializer" do
    test_type = TestType.new( :notExist => "testing")
    lambda do
      test_type.notExist
    end.should raise_error NoMethodError
    lambda do
      test_type.notExist = "Value"
    end.should raise_error NoMethodError
  end

  it "should not convert empty hash" do
    test_type = TestType.new( :fromCurrency => {} )
    test_type.to_hash.should eql({})
  end

  it "should not convert empty array" do
    test_type = TestType.new( :toCurrency => [] )
    test_type.to_hash.should eql({})
  end

  it "should not convert array of empty hash" do
    test_type = TestType.new( :toCurrency => [ {} ] )
    test_type.to_hash.should eql({})
  end

  it "should return empty hash" do
    test_type = TestType.new
    test_type.to_hash.should eql({})
  end

  it "should convert to hash" do
    test_currency = TestCurrency.new(:amount => "500")
    test_currency.to_hash.should eql("amount" => "500")
  end

  it "should convert to hash with key as symbol" do
    test_currency = TestCurrency.new(:amount => "500")
    test_currency.to_hash(:symbol => true).should eql(:amount => "500")
  end

  it "should convert attribute key with @" do
    test_currency = TestCurrency.new( :currencyID => "USD", :amount => "50" )
    test_currency.to_hash["@currencyID"].should eql "USD"
  end

  it "should convert attribute key without @" do
    test_currency = TestCurrency.new( :currencyID => "USD", :amount => "50" )
    test_currency.to_hash(:attribute => false)["currencyID"].should eql "USD"
  end

  it "should convert to hash with namespace" do
    test_currency = TestCurrency.new(:currencyID => "USD", :amount => "500", :desciption => "Testing" )
    hash = test_currency.to_hash
    hash["amount"].should eql "500"
    hash["ns:desciption"].should eql "Testing"
    hash["@currencyID"].should eql "USD"
    hash = test_currency.to_hash(:namespace => false)
    hash["amount"].should eql "500"
    hash["desciption"].should eql "Testing"
    hash["@currencyID"].should eql "USD"
  end

  it "should allow namespace" do
    test_currency = TestCurrency.new(:amount => "500", :"ns:desciption" => "Testing" )
    test_currency.desciption.should eql "Testing"
  end

  it "should use name option in members" do
    test_type = TestType.new( :firstname => "FirstName")
    test_type.to_hash.should eql({"first-name" => "FirstName" })
  end

  it "should allow date" do
    date_time = "2010-10-10T10:10:10"
    test_simple_type = TestSimpleType.new( :created_on => date_time, :created_at => date_time )
    test_simple_type.created_on.should be_a Date
    test_simple_type.created_at.should be_a DateTime
  end

  it "should allow date with value 0" do
    test_simple_type = TestSimpleType.new( :created_at => "0" )
    test_simple_type.created_at.should be_a DateTime
  end

end

