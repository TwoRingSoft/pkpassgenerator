init:
	# ensure Homebrew is installed
	which brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	# ensure jq is installed
	which jq || brew install jq
	# ensure there's a pass.json ready to go
	stat pass.json || cp pass.json.template pass.json

tools: ImagesSizeChecker signpass
	mkdir -p bin
	xcrun xcodebuild -scheme ImagesSizeChecker -derivedDataPath bin -configuration Release
	xcrun xcodebuild -scheme signpass -derivedDataPath bin -configuration Release
	mv bin/Build/Products/Release/ImagesSizeChecker bin/Build/Products/Release/signpass bin

pass: tools
	sh create-pass.sh .
