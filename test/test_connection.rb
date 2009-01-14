require File.dirname(__FILE__) + '/test_helper.rb'

class TestConnection < Test::Unit::TestCase
  include RShoeboxed
  
  def setup
    @conn = Connection.new("api_key", "user_token")
  end
  
  def test_authenticate__connection_failures
    assert true
  end
  
  def test_authentication_url__success_with_options
    assert_equal "https://www.shoeboxed.com/ws/api.htm?appname=Bootstrap&appurl=http%3A%2F%2Fexample.com&apparams=test%3D1%26test2%3D1&SignIn=1", 
      Connection.authentication_url("Bootstrap", "http://example.com", [[:test, 1], [:test2, 1]])
  end
  
  
  def test_authentication_url__success_no_options
    assert_equal "https://www.shoeboxed.com/ws/api.htm?appname=Bootstrap&appurl=http%3A%2F%2Fexample.com&apparams=&SignIn=1", 
      Connection.authentication_url("Bootstrap", "http://example.com")
  end
  
  def test_connection__instantiate_object
    assert_equal "api_key", @conn.api_key
    assert_equal "user_token", @conn.user_token
  end
  
  
  def test_get_receipt_info_call__success_getting_one_receipt
    request = fixture_xml_content("receipt_info_request")
    response = fixture_xml_content("receipt_info_response")
    
    conn = Connection.new("api_key", "user_token")
    conn.expects(:post_xml).with(request).returns(response)
    
    receipt = conn.get_receipt_info_call('1')
    assert_not_nil receipt
    assert_equal "1", receipt.id
    assert_equal "Morgan Imports", receipt.store
    assert_equal Date.new(2008, 5, 12), receipt.date
    assert_equal BigDecimal.new("1929.00"), receipt.total
    assert_equal "http://www.shoeboxed.com/receipt.jpeg", receipt.image_url
  end
  
  def test_build_receipt_info_call_request
    assert_equal fixture_xml_content("receipt_info_request"), @conn.send(:build_receipt_info_request, "1")
  end
  
  # def test_post_xml
  #   xml = "<test></test>"
  #   assert_nothing_raised do
  #     @conn.send(:post_xml, xml)
  #   end
  # end
  
  def test_get_receipt_call__success_getting_two_receipt
    request = fixture_xml_content("receipt_request")
    response = fixture_xml_content("receipt_response")
    
    conn = Connection.new("api_key", "user_token")
    conn.expects(:post_xml).with(request).returns(response)
    
    receipts = conn.get_receipt_call('1900-01-01T00:00:10', '2100-12-12T00:00:10')
    assert_equal 2, receipts.size
    
    receipt = receipts[0]
    assert_equal "23984923842", receipt.id
    assert_equal "Great Plains Trust Company", receipt.store
    assert_equal Date.new(2008, 5, 12), receipt.date
    assert_equal BigDecimal.new("3378.30"), receipt.total
    assert_equal "http://www.shoeboxed.com/receipt1.jpeg", receipt.image_url
    
    receipt = receipts[1]
    assert_equal "39239293", receipt.id
    assert_equal "RadioShack", receipt.store
    assert_equal Date.new(2008, 5, 12), receipt.date
    assert_equal BigDecimal.new("3.51"), receipt.total
    assert_equal "http://www.shoeboxed.com/receipt2.jpeg", receipt.image_url
  end
  
  def test_build_receipt_call_request
    assert_equal fixture_xml_content("receipt_request"), @conn.send(:build_receipt_request, 50, 1, '1900-01-01T00:00:10', '2100-12-12T00:00:10')
  end
  
  def test_check_for_api_error__all_error_codes
    assert_api_error_raised("receipt_response_bad_credentials", AuthenticationError, "Bad credentials")
    assert_api_error_raised("receipt_response_unknown_api_call", UnknownAPICallError, "Unknown API Call")
    assert_api_error_raised("receipt_response_restricted_ip", RestrictedIPError, "Restricted IP")
    assert_api_error_raised("receipt_response_xml_validation", XMLValidationError, "XML Validation")
    assert_api_error_raised("receipt_response_unknown_api_call", UnknownAPICallError, "Unknown API Call")
  end
  
  def test_check_for_api_error__no_error
    assert_nothing_raised do
      assert_equal "", @conn.send(:check_for_api_error, "")
    end
    
    response = fixture_xml_content("receipt_info_response")
    assert_nothing_raised do
      assert_equal response, @conn.send(:check_for_api_error, response)
    end
  end
  
private

  def assert_api_error_raised(response_fixture, error_type, error_message)
    response = fixture_xml_content(response_fixture)
    begin
      @conn.send(:check_for_api_error, response)
      fail "#{error_type.to_s} was not thrown"
    rescue error_type => e
      assert_equal error_message, e.message
    end
  end
end
