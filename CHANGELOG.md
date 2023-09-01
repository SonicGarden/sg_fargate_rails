## [Unreleased]

## [0.1.5](https://github.com/SonicGarden/sg_fargate_rails/compare/v0.1.4...v0.1.5)

- アクセス元IPアドレスの制限で複数IPアドレスを指定可能に

### Breaking Changes

- アクセス元IPアドレス制限の設定方法が変更されています。
    - 環境変数を使用する場合: `SG_PROXY_IP_ADDRESS` → `SG_PROXY_IP_ADDRESSES`
    - コードで設定する場合: `config.proxy_ip_address` → `config.proxy_ip_addresses`

## [0.1.4](https://github.com/SonicGarden/sg_fargate_rails/compare/v0.1.3...v0.1.4)

- メンテナンスモードの仕組みを追加
- foreman依存の削減
- puma依存の追加

## [0.1.3](https://github.com/SonicGarden/sg_fargate_rails/compare/v0.1.2...v0.1.3)

- アクセス元IPアドレスの制限を入れる仕組みを追加

## [0.1.2](https://github.com/SonicGarden/sg_fargate_rails/compare/v0.1.1...v0.1.2)

- HTTP_X_FORWARDED_PROTOを調整する仕組みを導入(cloudfront対応)

## [0.1.1](https://github.com/SonicGarden/sg_fargate_rails/compare/v0.1.0...v0.1.1)

- healthcheckの仕組み導入

## [0.1.0]

- foreman とlograge を自動で読み込むように
