const String certificateStorageABI = r'''
[
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "string",
        "name": "certId",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "certHash",
        "type": "string"
      }
    ],
    "name": "CertificateAdded",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_certId",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "_issuer",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "_issuedDate",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "_certHash",
        "type": "string"
      }
    ],
    "name": "addCertificate",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_certId",
        "type": "string"
      }
    ],
    "name": "verifyCertificate",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
''';