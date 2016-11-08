#レポート課題4

氏名: 阿部修也  

##課題内容

##課題解答


#作業メモ（レポート範囲外）
誰かのお役に立つこともあるかもなので
なんかうまくいかなかったところをメモ。

前半はすべての課題で共通だけど、特に他の課題レポートにメモをつける予定はありませぬ。

##うまくいかないときに確認
###rubyのバージョン
rvm list等で現在利用中のバージョン確認。
必要なら変更。

ちなみに、gem install bundler やbundle install --binstubsはrubyのバージョンごとに行わないといけないので注意

###network manager
sudoを使ってコマンドでオンオフでも良いけど、
GUIでデスクトップ右上のネットワークアイコンから
「ネットワークを有効にする」のチェックを外すのでもOK

オフにした状態でtremaは実行する

###tremaのプロセスのpidファイル（残骸）
何かしらエラーが出るなどして、trema実行中にプログラムが「落ちた」場合、
プロセスを殺した時に残骸としてpidファイル等々が/tmpに残る。
これを削除しないと実行不可

その他もろもろ残ってるので/tmpの中身は全部消しちゃうのがよいかと
```
rm /tmp/*
```

###openvswitchの残骸
エラーメッセージをメモるの忘れたけど、
そのスイッチもうあるんだよね、みたいなことを言われた場合は
エラー終了などによってswitchプロセスが残ってしまっている可能性がある。

もちろん、dslで書いたconf（trema.confとか。-cオプションで読み込むネットワーク設定ファイル）を読んでくる場合は
そこに登場するスイッチのidを変更することでも逃げられるが
本質的な解決じゃないので非推奨

tremaはOpenvswitchを使ってスイッチを立てているので
直接Openvswitchのコマンドで殺す
```
sudo ovs-vsctl del-br <switch name: default=br0x1>
```

###namespaceが定義済み
普通のhostの場合は
trema killall <hostname>
かなんかで殺せた気がするけど、
netnsはちゃんと死んでくれないので以下を利用。
これも、tremaがipコマンドでnamespaceを定義していることを使ってる。
```
sudo ip netns delete <hostname: default1=host1, default2=host2>
```


##reset用にshellscriptでも用意すれば楽かも（ただしパスは通さないほうがよい）
場合によって不要な処理は入ってるけど、
以下を実行すればネットワークのオンオフが間違ってる場合をのぞいてだいたい直るので
shellscriptにでもしておけばどうだろう…
課題ごとにreset用のスクリプト作ると楽だと思う
```
sudo rm /tmp/*
./bin/trema killall --all
sudo ovs-vsctl del-br br0x1
sudo ip netns delete host1
sudo ip netns delete host2
```


