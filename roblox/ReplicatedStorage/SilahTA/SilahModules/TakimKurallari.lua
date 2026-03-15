return {
	Teams = {
		["Askeri İnzibat"] = {"Türk Silahlı Kuvvetleri", "İsyancılar", "Sivil", "Jandarma", "Sınır Müfettişleri", "Özel Kuvvetler", "Hapis", "Ordu Subayları", "Kara Kuvvetleri", "Hava Kuvvetleri"},
		["DY"] = {},
		["Hapis"] = {},
		["Hava Kuvvetleri"] = {"İsyancılar"},
		["Jandarma"] = {"İsyancılar"},
		["Kara Kuvvetleri"] = {"İsyancılar"},
		["Ordu Subayları"] = {"İsyancılar", "Sivil"},
		["Sınır Müfettişleri"] = {"Sivil", "İsyancılar"},
		["Özel Kuvvetler"] = {"Türk Silahlı Kuvvetleri", "İsyancılar", "Jandarma", "Sivil", "Sınır Müfettişleri", "Askeri İnzibat", "Hapis", "Ordu Subayları", "Kara Kuvvetleri", "Hava Kuvvetleri"},
		["Türk Silahlı Kuvvetleri"] = {"İsyancılar"},
		["Sivil"] = {},
		["İsyancılar"] = {"Türk Silahlı Kuvvetleri", "Jandarma", "Sınır Müfettişleri", "Özel Kuvvetler", "Ordu Subayları", "Kara Kuvvetleri", "Hava Kuvvetleri", "Askeri İnzibat"},
	},
	Ranks = {
		{ Takimlar = {"Türk Silahlı Kuvvetleri", "İsyancılar", "Sivil"}, MinRank = 12, MaxRank = 13, TeamKill = false },
		{ Takimlar = {"Türk Silahlı Kuvvetleri", "İsyancılar", "Sivil"}, MinRank = 15, MaxRank = 21, TeamKill = false },
		{ Takimlar = {"Türk Silahlı Kuvvetleri", "İsyancılar", "Kara Kuvvetleri", "Hava Kuvvetleri", "Jandarma", "Sivil"}, MinRank = 21, MaxRank = 27, TeamKill = false },
		{ Takimlar = {"Türk Silahlı Kuvvetleri", "İsyancılar", "Kara Kuvvetleri", "Hava Kuvvetleri", "Jandarma", "Askeri İnzibat", "Sınır Müfettişleri", "Özel Kuvvetler", "Sivil"}, MinRank = 27, MaxRank = 256, TeamKill = false },
	},
}
