const BetHandler = artifacts.require("BetHandler");

module.exports = function (deployer) {
  deployer.deploy(BetHandler);
};
