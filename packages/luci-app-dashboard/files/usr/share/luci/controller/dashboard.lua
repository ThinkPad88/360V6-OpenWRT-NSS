module("luci.controller.dashboard", package.seeall)

function index()
    entry({"admin", "dashboard"}, template("dashboard/index"), _("ä»ªè¡¨ç"), 1)
end
