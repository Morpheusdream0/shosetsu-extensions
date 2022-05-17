-- {"id":1331219,"ver":"1.0.8","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://bakapervert.wordpress.com"

--- @param url string
--- @return string
local function shrinkURL(url)
	return url:gsub("^.-bakapervert%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
	return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("#content div")
    local p = content:selectFirst(".entry-content")

    local post_flair = content:selectFirst("div#jp-post-flair")
    if post_flair then post_flair:remove() end

    -- get last "p" to remove prev/next links
    local allElements = p:select("p")
    local lastElement = allElements:get(allElements:size()-1)
    if lastElement:children():size() > 0 and lastElement:attr("style"):find("center") then
		lastElement:remove()
    end

    return p
end

--- @param queryData string
--- @return table
local function getProjectNav(queryData)
	return map(doc:selectFirst(queryData):selectFirst("ul.sub-menu"):select("> li > a"), function (v)
		return v:attr("href")
	end)
end

--- @param url string
--- @param projects table
--- @return boolean
local function isProjectInTable(url, projects)
	for i = 1, #projects do
		if shrinkURL(projects[i]) == shrinkURL(url) then
			return true
		end
	end
	return false
end

return {
	id = 1331219,
	name = "bakapervert",
	baseURL = baseURL,
	imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Bakapervert.jpg",
	hasSearch = false,
	chapterType = ChapterType.HTML,

	-- Must have at least one value
	listings = {
		Listing("Novels", false, function(data)
			local doc = GETDocument(baseURL)
			return map(flatten(mapNotNil(doc:selectFirst("div#access ul"):children(), function(v)
				local text = v:selectFirst("a"):text()
				return (text:find("Projects", 0, true)) and
						map(v:selectFirst("ul.sub-menu"):select("> li > a"), function(v) return v end)
			end)), function(v)
				return Novel {
					title = v:text(),
					link = shrinkURL(v:attr("href"))
				}
			end)
		end)
	},

	getPassage = function(chapterURL)
		return pageOfElem(parsePage(chapterURL))
	end,

	parseNovel = function(novelURL, loadChapters)
		local doc = GETDocument(baseURL .. novelURL)
		local content = doc:selectFirst("#content div")

		local ongoingProject = getProjectNav("li#menu-item-5787")
		local finishedProject = getProjectNav("li#menu-item-12566")

		local info = NovelInfo {
			title = content:selectFirst(".entry-title"):text(),
			imageURL = content:selectFirst("img"):attr("src")
		}

		if isProjectInTable(novelURL, ongoingProject) then
			info:setStatus(NovelStatus.PUBLISHING)
		elseif isProjectInTable(novelURL, finishedProject) then
			info:setStatus(NovelStatus.COMPLETED)
		else
			info:setStatus(NovelStatus.UNKNOWN)
		end

		if loadChapters then
			local actualChapters = {}
			local selectedData = content:selectFirst(".entry-content"):select("p a")
			local actualOrder = 1
			for i = 0, #selectedData do
				local selectThis = selectedData:get(i)
				local hrefUrl = selectThis:attr("href")
				if (hrefUrl:find("bakapervert.wordpress.com")) then
					table.insert(actualChapters, NovelChapter {
						order = actualOrder,
						title = selectThis:text(),
						link = shrinkURL(hrefUrl)
					})
					actualOrder = actualOrder + 1
				end
			end
			info:setChapters(AsList(actualChapters))
		end

		return info
	end,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
