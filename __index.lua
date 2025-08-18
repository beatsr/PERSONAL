#!/usr/bin/env lua

local function capitalize_month_name(month_num)
	local month_names = {
		"JANUARY",
		"FEBRUARY",
		"MARCH",
		"APRIL",
		"MAY",
		"JUNE",
		"JULY",
		"AUGUST",
		"SEPTEMBER",
		"OCTOBER",
		"NOVEMBER",
		"DECEMBER",
	}
	return month_names[tonumber(month_num)]
end

local file_list = {}
for line in io.lines() do
	table.insert(file_list, line)
end

local month_files = {}
local all_months = {}

for _, filepath in ipairs(file_list) do
	local year_month, year, month_num, day, filename =
		filepath:match("^(Journal/(%d%d%d%d)/(%d%d))/(%d%d)/([^/]+%.md)$")

	if year_month and filename then
		if not month_files[year_month] then
			month_files[year_month] = { year = year, month_num = month_num, files = {} }
			table.insert(all_months, { path = year_month, year = year, month_num = month_num })
		end

		table.insert(month_files[year_month].files, {
			day = day,
			filename = filename:gsub("%.md$", ""),
		})
	end
end

for month_path, data in pairs(month_files) do
	local index_path = month_path .. "/index.md"
	local file = io.open(index_path, "w")

	if file then
		local month_name = capitalize_month_name(data.month_num)
		file:write(string.format("## %s %s\n\n", month_name, data.year))

		table.sort(data.files, function(a, b)
			return a.day < b.day
		end)

		for _, entry in ipairs(data.files) do
			file:write(string.format("- [[%s/%s|%s]]\n", entry.day, entry.filename, entry.filename))
		end

		file:close()
		print("Created: " .. index_path)
	else
		print("Error: Could not write to " .. index_path)
	end
end

local root_index = io.open("index.md", "w")
if root_index then
	root_index:write("# JOURNAL INDEX\n\n")

	-- 按年份和月份排序
	table.sort(all_months, function(a, b)
		if a.year == b.year then
			return a.month_num < b.month_num
		else
			return a.year > b.year -- 最近的年份在前
		end
	end)

	for _, month in ipairs(all_months) do
		local month_name = capitalize_month_name(month.month_num)
		root_index:write(string.format("- [[%s/index|%s %s]]\n", month.path, month_name, month.year))
	end

	root_index:close()
	print("\nCreated/Updated: ./index.md")
else
	print("\nError: Could not write to ./index.md")
end
