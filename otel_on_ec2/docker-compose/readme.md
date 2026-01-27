# observability stackの起動
1. docker-compose.yamlとprometheus.yamlを配置
2. docker compose up -dコマンドを実行
3. terraform apply後に表示されたgrafana_urlにアクセスできることを確認
4. admin/adminでログイン

# datasourceの追加
## prometheus
1. prometheus datasourceを追加、URLは`http://prometheus:9090`
2. exploreからprometheus_readyメトリクスが1であることを確認
## victoria logs
1. victorialogs datasourceを追加、URLは`http://vlselect:9471`
## victoria traces
1. jaeger datasourceを追加、URLは`http://victoria-traces:10428/select/jaeger`