require 'cosmos'
require 'cosmos/script'
require "generic_radio_lib.rb"

class RADIO_Functional_Test < Cosmos::Test
  def setup
      safe_RADIO()
  end

  def test_application
    start("tests/generic_radio_app_test.rb")
  end

  def test_device
    start("tests/generic_radio_device_test.rb")
  end

  def teardown
    safe_RADIO()
  end
end

class RADIO_Scenario_Test < Cosmos::Test
  def setup
    safe_RADIO()
  end

  def test_AST
    start("tests/generic_radio_ast_test.rb")
  end

  def teardown
    safe_RADIO()
  end
end

class Generic_radio_Test < Cosmos::TestSuite
  def initialize
      super()
      add_test('RADIO_Functional_Test')
      add_test('RADIO_Scenario_Test')
  end

  def setup
    safe_RADIO()
  end
  
  def teardown
    safe_RADIO()
  end
end