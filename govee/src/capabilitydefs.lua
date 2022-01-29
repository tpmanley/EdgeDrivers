local textField = [[
{
    "id": "partyvoice23922.textfield",
    "version": 1,
    "status": "proposed",
    "name": "textField",
    "attributes": {
        "text": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "enumCommands": []
        }
    },
    "commands": {}
}
]]
return  {
    textField = textField,
}
