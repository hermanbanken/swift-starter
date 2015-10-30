echo "Installing version-locked swift-json-gen"
npm install --dev swift-json-gen@0.2.2

echo "Generating JSON..."
node node_modules/swift-json-gen/bin/swift-json-gen DOH/Models/Json/

echo "Done!"