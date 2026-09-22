module("luci.controller.dashboard", package.seeall)

function index()
    entry({"admin", "dashboard"}, template("dashboard/index"), _("Dashboard"), 1)
end
