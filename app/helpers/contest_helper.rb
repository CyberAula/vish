module ContestHelper 
	def contest_page_path(contest,pageName=nil,useName=true)
		if useName
			contestPath = "/contest/" + contest.name	
		else
			contestPath = contest_path(contest)
		end
		unless pageName.blank? or pageName=="index"
			contestPath + "/page/" + pageName
		else
			contestPath
		end
	end
end