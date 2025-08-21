#!/usr/bin/env lua

-- 将月份数字转换为大写月份名称
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

-- 读取所有文件路径
local function read_file_list()
	local file_list = {}
	for line in io.lines() do
		table.insert(file_list, line)
	end
	return file_list
end

-- 解析文件路径，提取年月日信息
local function parse_file_paths(file_list)
	local month_files = {}
	local all_months = {}

	for _, filepath in ipairs(file_list) do
		local year_month, year, month_num, day, filename =
			filepath:match("^(Journal/(%d%d%d%d)/(%d%d))/(%d%d)/([^/]+%.md)$")

		if year_month and filename then
			-- 初始化月份数据结构
			if not month_files[year_month] then
				month_files[year_month] = {
					year = year,
					month_num = month_num,
					files = {},
				}
				table.insert(all_months, {
					path = year_month,
					year = year,
					month_num = month_num,
				})
			end

			-- 添加文件信息
			table.insert(month_files[year_month].files, {
				day = day,
				filename = filename:gsub("%.md$", ""),
			})
		end
	end

	return month_files, all_months
end

-- 创建单个月份的索引文件
local function create_month_index(month_path, data)
	local index_path = month_path .. "/index.md"
	local file = io.open(index_path, "w")

	if not file then
		print("Error: Could not write to " .. index_path)
		return false
	end

	local month_name = capitalize_month_name(data.month_num)
	file:write(string.format("## %s %s\n\n", month_name, data.year))

	-- 按日期排序，最新的在前面（降序）
	table.sort(data.files, function(a, b)
		return tonumber(a.day) > tonumber(b.day)
	end)

	-- 写入文件链接
	for _, entry in ipairs(data.files) do
		file:write(string.format("- [[%s/%s|%s]]\n", entry.day, entry.filename, entry.filename))
	end

	file:close()
	print("Created: " .. index_path)
	return true
end

-- 创建所有月份索引文件
local function create_month_indexes(month_files)
	for month_path, data in pairs(month_files) do
		create_month_index(month_path, data)
	end
end

-- 创建根索引文件
local function create_root_index(all_months)
	local root_index = io.open("index.md", "w")

	if not root_index then
		print("\nError: Could not write to ./index.md")
		return false
	end

	root_index:write("# JOURNAL INDEX\n\n")

	-- 按年份和月份排序（最新的年份和月份在前）
	table.sort(all_months, function(a, b)
		if a.year == b.year then
			return tonumber(a.month_num) > tonumber(b.month_num)
		else
			return tonumber(a.year) > tonumber(b.year)
		end
	end)

	-- 写入月份链接
	for _, month in ipairs(all_months) do
		local month_name = capitalize_month_name(month.month_num)
		root_index:write(string.format("- [[%s/index|%s %s]]\n", month.path, month_name, month.year))
	end

	root_index:close()
	print("\nCreated/Updated: ./index.md")
	return true
end

-- 主函数
local function main()
	local file_list = read_file_list()
	local month_files, all_months = parse_file_paths(file_list)

	create_month_indexes(month_files)
	create_root_index(all_months)
end

-- 执行主函数
main()
