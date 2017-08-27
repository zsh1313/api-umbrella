local common_validations = require "api-umbrella.utils.common_validations"
local json_null = require("cjson").null
local model_ext = require "api-umbrella.utils.model_ext"
local t = require("resty.gettext").gettext
local validation = require "resty.validation"

local validate_field = model_ext.validate_field

local ApiBackendServer = model_ext.new_class("api_backend_servers", {
  as_json = function(self)
    return {
      id = self.id or json_null,
      host = self.host or json_null,
      port = self.port or json_null,
    }
  end,
}, {
  validate = function(_, data)
    local errors = {}
    validate_field(errors, data, "host", validation.string:minlen(1), t("can't be blank"))
    validate_field(errors, data, "host", validation.optional:regex(common_validations.host_format, "jo"), t('must be in the format of "example.com"'))
    validate_field(errors, data, "port", validation.number, t("can't be blank"))
    validate_field(errors, data, "port", validation.number:between(0, 65535), t("is not included in the list"))
    return errors
  end,
})

return ApiBackendServer
