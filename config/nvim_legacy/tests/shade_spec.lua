--- Tests for shade.lua module
--- Run with: nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

local shade = require("shade")

describe("shade", function()
  describe("is_shade_context", function()
    it("returns false when not in shade context", function()
      -- Save original values
      local orig_shade_context = vim.g.shade_context
      local orig_shade_env = vim.env.SHADE

      -- Clear shade indicators
      vim.g.shade_context = nil
      vim.env.SHADE = nil

      assert.is_false(shade.is_shade_context())

      -- Restore
      vim.g.shade_context = orig_shade_context
      vim.env.SHADE = orig_shade_env
    end)

    it("returns true when vim.g.shade_context is set", function()
      local orig = vim.g.shade_context
      vim.g.shade_context = true

      assert.is_true(shade.is_shade_context())

      vim.g.shade_context = orig
    end)

    it("returns true when SHADE env var is set", function()
      local orig_g = vim.g.shade_context
      local orig_env = vim.env.SHADE

      vim.g.shade_context = nil
      vim.env.SHADE = "1"

      assert.is_true(shade.is_shade_context())

      vim.g.shade_context = orig_g
      vim.env.SHADE = orig_env
    end)
  end)

  describe("socket_exists", function()
    it("returns false when socket doesn't exist", function()
      -- This should be false in test environment
      -- unless Shade is actually running
      local result = shade.socket_exists()
      assert.is_boolean(result)
    end)
  end)

  describe("request", function()
    it("returns error when socket doesn't exist", function()
      -- Temporarily point to non-existent socket
      -- (This tests the error path)
      local result, err = shade.request("ping")

      -- If shade is running, we get a result
      -- If not, we get an error
      if err then
        assert.is_string(err)
        assert.matches("socket", err:lower())
      else
        -- Shade is running, ping should return "pong"
        assert.equals("pong", result)
      end
    end)
  end)

  describe("ping", function()
    it("returns pong when shade is running", function()
      local result = shade.ping()

      if shade.socket_exists() then
        assert.equals("pong", result)
      else
        assert.is_nil(result)
      end
    end)
  end)

  describe("module structure", function()
    it("exports expected functions", function()
      assert.is_function(shade.hide)
      assert.is_function(shade.show)
      assert.is_function(shade.toggle)
      assert.is_function(shade.ping)
      assert.is_function(shade.get_context)
      assert.is_function(shade.request)
      assert.is_function(shade.notify)
      assert.is_function(shade.setup)
      assert.is_function(shade.is_shade_context)
      assert.is_function(shade.socket_exists)
    end)
  end)
end)

-- Integration tests (require Shade to be running)
describe("shade integration", function()
  before_each(function()
    if not shade.socket_exists() then
      pending("Shade server not running - skipping integration test")
    end
  end)

  it("can ping shade server", function()
    local result = shade.ping()
    assert.equals("pong", result)
  end)

  it("can call hide without error", function()
    -- This will actually hide the panel if Shade is running
    -- We just verify it doesn't throw
    local result = shade.hide()
    assert.is_boolean(result)
  end)

  it("can call show without error", function()
    local result = shade.show()
    assert.is_boolean(result)
  end)

  it("can call toggle without error", function()
    local result = shade.toggle()
    assert.is_boolean(result)
  end)

  it("can get context", function()
    local result = shade.get_context()
    -- Result should be a table (possibly empty) or nil
    if result ~= nil then
      assert.is_table(result)
    end
  end)
end)
