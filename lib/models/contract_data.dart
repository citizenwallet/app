class ContractData {
  final String sourceCode;
  final String abi;
  final String contractName;
  final String compilerVersion;
  final String optimizationUsed;
  final String runs;
  final String constructorArguments;
  final String evmVersion;
  final String library;
  final String licenseType;
  final String proxy;
  final String implementation;
  final String swarmSource;

  ContractData({
    required this.sourceCode,
    required this.abi,
    required this.contractName,
    required this.compilerVersion,
    required this.optimizationUsed,
    required this.runs,
    required this.constructorArguments,
    required this.evmVersion,
    required this.library,
    required this.licenseType,
    required this.proxy,
    required this.implementation,
    required this.swarmSource,
  });

  factory ContractData.fromJson(Map<String, dynamic> json) {
    return ContractData(
      sourceCode: json['SourceCode'] ?? '',
      abi: json['ABI'] ?? '',
      contractName: json['ContractName'] ?? '',
      compilerVersion: json['CompilerVersion'] ?? '',
      optimizationUsed: json['OptimizationUsed'] ?? '',
      runs: json['Runs'] ?? '',
      constructorArguments: json['ConstructorArguments'] ?? '',
      evmVersion: json['EVMVersion'] ?? '',
      library: json['Library'] ?? '',
      licenseType: json['LicenseType'] ?? '',
      proxy: json['Proxy'] ?? '',
      implementation: json['Implementation'] ?? '',
      swarmSource: json['SwarmSource'] ?? '',
    );
  }
}
