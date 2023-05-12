const fs = require("fs");
const path = require("path");

const inputFile =
  "/Users/lukas/Documents/Business/Development/Fiverr/active/NFTMintingContract/NFTMinting/GenerateNFTs/PABLO.json";
const outputFolder =
  "/Users/lukas/Documents/Business/Development/Fiverr/active/NFTMintingContract/NFTMinting/GenerateNFTs/metadata";

// Read input JSON data from file
const inputJson = JSON.parse(fs.readFileSync(inputFile, "utf8"));

function createIndividualJsonFiles(data) {
  // Create the output folder if it doesn't exist
  if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder);
  }

  data.forEach((item, index) => {
    // Modify the image property to include the item name in the URL
    item.image =
      "ipfs://bafybeifc2qhk6khmzyixif3jwu7v7ucgc5esx4erdoqy7a4j3iaswbz2oa" + "/" + item.name.replace(/ /g, "") + ".png";

    // Create a new JSON file with the item data in the output folder
    fs.writeFileSync(
      path.join(outputFolder, `${index}`),
      JSON.stringify(item, null, 2)
    );
  });
}

createIndividualJsonFiles(inputJson);
