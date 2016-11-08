#レポート課題4

氏名: 阿部修也  

##課題内容
ルータのコマンドラインインターフェース（CLI）を作成せよ．
ただし，以下の操作を実装すること．

* ルーティングテーブルの表示
* ルーティングテーブルエントリの追加と削除
* ルータのインタフェース一覧の表示
* そのほか、あると便利な機能

##課題解答
実行するコマンドラインインターフェースは[bin/routercli](https://github.com/handai-trema/simple-router-shuya-abe/blob/develop/bin/routercli)というバイナリとして作成している．

また，各課題における機能は，このroutercliのサブコマンドとして実装している．

### ルーティングテーブルの表示
ルーティングテーブルの情報を保持するlib/routing_table.rb中の@dbの要素を出力すればよい．
ただし，出力先はbin/routercliを実行している側のコンソールであるため，
bin/routercliがlib/routing_table.rbを読み込むlib/simple_router.rb中のメソッドの戻り値を受け取る必要がある．

ルーティングテーブルの表示は以下のようにして行う．
```
bin/routercli show_table 
```
####routercli
lib/simple_router.rbを呼び出し，show_tableメソッドを実行し，戻り値strを出力する．
このとき，strは出力を一行ずつ格納した配列であるため，これを改行区切りでコンソールに出力する．
```ruby
  desc 'Show routing table entries'
  arg_name ''
  command :show_table do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      str = Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        show_table()
      print(str.join("\n"))
    end
  end
```

####simple_router.rb
#####show_table
bin/routercliから呼び出され，show_table_entriesを呼び出すメソッド．
@routing_tableがnilの場合はエントリーがないことを表示して終了する．
```ruby
  def show_table
    return "no entries" if @routing_table.nil?
    show_table_entries
  end
```

#####show_table_entries (private)
lib/routing_table.rbのRoutingTableクラスのメソッドshowを@routing_tableに実行する．
```ruby
  def show_table_entries
    return @routing_table.show
  end
```

####routing_table.rb
次の転送先をネットマスク及び宛先ごとに格納した連想配列@dbの各要素を取得し，出力文字列に追加する．
出力文字列は一次元配列に格納され，bin/routercliに戻り値として渡される．

その際，@dbにはIPアドレスが整数値として格納されているため，IPAddrのnewメソッドを利用して表示を変更している．
```ruby
  def show
    entries = []
    entries.push("dst/mask, nexthop")
    entries.push("=================")
    MAX_NETMASK_LENGTH.downto(0).each do |each|
      @db[each].each do |k, v|
        entries.push("#{IPAddr.new(k, Socket::AF_INET).to_s}/#{each}, #{v.to_s}")
      end
    end
    entries.push("")
    return entries
  end
```

### ルーティングテーブルエントリの追加と削除
routing_table.rbには，すでにエントリを追加するためのメソッドは存在しているため，
削除するためのメソッドはこれに基づいて作成すればよい．
ただし，次の転送先については削除時には指定しないため，引数の数が異なる．

ルーティングテーブルエントリの追加及び削除は以下のようにして行う．
ただし，<dst>は宛先アドレス，<masklen>はマスク長，<nexthop>は次の転送先である．
```
[追加]
bin/routercli add <dst> <masklen> <nexthop>

[削除]
bin/routercli delete <dst> <masklen>
```

####routercli
エントリを追加するためのサブコマンドadd及びdeleteによってlib/simple_router.rb内のadd_entryメソッド及びdelete_entryメソッドをそれぞれ呼び出す．
ここでは引数を渡すのみで，戻り値は受け取らない．
```ruby
  desc 'Add a entry'
  arg_name 'dst, masklen, nexthop'
  command :add do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      dst = args[0]
      masklen = args[1].to_i
      nexthop = args[2]
      Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        add_entry(dst, masklen, nexthop)
    end
  end

  desc 'Delete a entry'
  arg_name 'dst, masklen'
  command :delete do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      dst = args[0]
      masklen = args[1].to_i
      Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        delete_entry(dst, masklen)
    end
  end
```

####simple_router.rb
ルーティングテーブルの内容はRoutingTableクラスのオブジェクト@routing_tableが保持している．
@routing_tableに対して，RoutingTableクラスのメソッドを実行する処理を行っている．

#####add_entry
エントリの追加命令を受け取り，エントリを追加するためのプライベートメソッド，
add_routing_entriesを呼び出す．
```ruby
  def add_entry(dst, masklen, nexthop)
    add_routing_entries(dst, masklen, nexthop)
  end
```

#####delete_entry
エントリの削除命令を受け取り，エントリを削除するためのプライベートメソッド，
delete_routing_entriesを呼び出す．
```ruby
  def delete_entry(dst, masklen)
    delete_routing_entries(dst, masklen)
  end
```

#####add_routing_entries (private)
RoutingTableクラスの既存メソッドであるaddメソッドを呼び出し，エントリの追加を行っている．
引数にマスク長，宛先アドレス，次の転送先からなる連想配列を指定している．
```ruby
  def add_routing_entries(dst, masklen, nexthop)
    @routing_table.add({
      netmask_length: masklen,
      destination: dst,
      next_hop: nexthop
    })
  end
```

#####delete_routing_entries (private)
RoutingTableクラスの新規メソッドであるdeleteメソッドを呼び出し，エントリの削除を行っている．
引数にマスク長，宛先アドレスからなる連想配列を指定している．
```ruby
  def delete_routing_entries(dst, masklen)
    @routing_table.delete({
      netmask_length: masklen,
      destination: dst
    })
  end
```

####routing_table.rb
既存のaddメソッドをもとに，deleteメソッドを作成した．
引数としてマスク長及び宛先アドレスからなる連想配列optionsを受け取り，
ルーティングテーブルの情報を保持する連想配列@dbからエントリを削除する．
（@dbは，ネットマスク長ごとに，また，宛先ネットワークアドレスごとに情報を保持している．）
```ruby
  def delete(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    @db[netmask_length].delete(prefix.to_i)
  end
```

### ルータのインタフェース一覧の表示
ルータのインタフェースの情報を保持するlib/interface.rb中のallの要素を出力すればよい．
ただし，出力先はbin/routercliを実行している側のコンソールであるため，
bin/routercliがlib/interface.rbを読み込むlib/simple_router.rb中のメソッドの戻り値を受け取る必要がある．

ルータのインタフェースの表示は以下のようにして行う．
```
bin/routercli show_interface 
```

####routercli
lib/simple_router.rbを呼び出し，show_interfaceメソッドを実行し，戻り値strを出力する．
このとき，strは出力を一行ずつ格納した配列であるため，これを改行区切りでコンソールに出力する．
```ruby
  desc 'Show interface list'
  arg_name ''
  command :show_interface do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      str = Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        show_interface()
      print(str.join("\n"))
    end
  end
```

####simple_router.rb

#####show_interface
bin/routercliから呼び出され，show_interface_entriesを呼び出すメソッド．
```ruby
  def show_interface
    show_interface_entries
  end
```

#####show_interface_entries (private)
ルータの各インターフェースについて，
ポート番号，MACアドレス及びIPアドレスをひとまとまりのエントリとして格納したallの各要素を取得し，出力文字列に追加する．
出力文字列は一次元配列に格納され，bin/routercliに戻り値として渡される．
```ruby
  def show_interface_entries
    entries = []
    entries.push("port, mac, ip")
    entries.push("=============")
    Interface.all.each do |each|
      entries.push("#{each.port_number}, #{each.mac_address}, #{each.ip_address.value}/#{each.netmask_length}")
    end
    entries.push("")
    return entries
  end
```

###動作確認
以下のようにして動作確認を行った．
ただし，ルータやホストなどに関する設定ファイルは課題リポジトリ内のサンプルファイル（trema.conf）を用いている．
また，各ステップにおいて，ルーティングテーブルのエントリ一覧を表示する．
```
1. ルータを起動する
2. ルーティングテーブルにエントリを追加する
3. ルーティングテーブルからエントリを削除する
4. インターフェースの一覧を表示する
```

####1. ルータを起動する
このとき，ルーティングテーブルはデフォルトのエントリが追加された状態である．
```
[routercli show_table]
dst/mask, nexthop
=================
0.0.0.0/0, 192.168.1.2
```

####2. ルーティングテーブルにエントリを追加する
宛先ネットワークアドレス，サブネットマスク長，転送先アドレスを指定し，
ルーティングテーブルエントリ追加のためのサブコマンドaddを実行する．

実行後，確かにテーブルにはエントリが追加されている．
```
routercli add 192.168.2.0 24 192.168.2.1

[routercli show_table]
dst/mask, nexthop
=================
192.168.2.0/24, 192.168.2.1
0.0.0.0/0, 192.168.1.2
```

####3. ルーティングテーブルからエントリを削除する
宛先ネットワークアドレス，サブネットマスク長を指定し，
ルーティングテーブルエントリ削除のためのサブコマンドdeleteを実行する．

実行後，確かにテーブルからはエントリが削除されている．
```
routercli delete 192.168.2.0 24

[routercli show_table]
dst/mask, nexthop
=================
0.0.0.0/0, 192.168.1.2
```

####4. インターフェースの一覧を表示する
最後に，ルータのインターフェース一覧を表示する．
これはtrema.confによって指定したインターフェースの情報と一致する．
```
[routercli show_interface]
port, mac, ip
=============
1, 01:01:01:01:01:01, 192.168.1.1/24
2, 02:02:02:02:02:02, 192.168.2.1/24
```


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


