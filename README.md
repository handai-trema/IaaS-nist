# スイッチの統計情報に基づく課金サービスとDoS攻撃対策を備えたIaaS

## 概要
Virtualbox と OpenFlow を用いて スイッチの統計情報を利用する IaaS
を作成した。
ユーザ（クラウド利用者）は Web インターフェースにより
仮想マシン（VM）を作成・削除・起動・停止・課金プランの選択をすることができる。

OpenFlow（Trema）によって、統計情報が取得されており、
この統計情報を用いることで、ユーザーの通信状況を把握し動的なサービス変更、ならびにネットワーク側でDoS攻撃のような悪意のあるユーザーを検知し、安全なネットワークサービスを提供する。



## 発表用PPTXファイル
発表用PPTXファイルは[こちら](./img/enshu_final_ver3.pptx)  
レポートは[こちら](./img/enshu_final_report.pptx)

## 成果物の説明

* Controller のソースコード
	* Controller 操作に関するモジュールは主に /lib/ に配置
	* /trema/ に統計情報取得のために改変したファイル（[controller.rb](https://github.com/handai-trema/IaaS-nist/tree/master/trema/controller.rb))を配置
* WEBインターフェース
	* 
* VMマネージャー
	* Webインターフェースから受け取ったイベントを元に起動するシェルスクリプトの作成
	* /WebInterface/IaaS-system に（[create.sh](https://github.com/handai-trema/IaaS-nist/tree/master/WebInterface/iaas-system/create.sh),[stop.sh](https://github.com/handai-trema/IaaS-nist/tree/master/WebInterface/iaas-system/stop.sh),[connect.sh](https://github.com/handai-trema/IaaS-nist/tree/master/WebInterface/iaas-system/connect.sh))を配置

## 実機スイッチのセットアップ
### 初期設定
設定用端末ととPF5240のコンソールポートをRS232Cケーブルで接続し、
以下の事項を、実機スイッチに対して一度実行する。

1. Tera Term の起動

1. 以下のシリアルポートで接続
    * 通信速度: 9600bps
    * データ長: 8bit
    * パリティビット: なし
    * ストップビット: 1bit
    * フロー制御: なし
1. ログイン
    * username : operator
    * password : \<none>
1. コンフィグレーションコマンドモードで実行

			> enable
			# configure

1. マネジメントポート設定

			(config)# interface mgmt 0
			(config-if)# ip address 192.168.1.1 255.255.255.0
			(config-if)# exit

1. telnet接続許可

			(config)# line vty 0 2
			(config-line)# exit

1. システムクロックの設定

			(config)# clock timezone JST +9

1. Spanning-tree無効化

			(config)# spanning-tree disable

1. フローコントロール無効化

			(config)# system flowcontrol off

1. 保存

			(config)# save


### 設定用端末の設定
設定用端末とコントローラは同一のマシンである。

1. 物理接続  
設定用端末とPF5240のマネジメントポートをLANケーブルで接続
1. 設定用端末で Virtualbox を起動。
1. ID:ensyuu2 / Password:ensyuu2 でログイン。
1. Controller に IP アドレスを設定  
	* アドレス：192.168.1.2  
	* サブネットマスク：255.255.255.0  
	* ゲートウェイ:192.168.1.1
1. 設定用端末設定

			$ sudo ip addr add 192.168.1.2/24 dev eth0

1. telnet でPF5240にアクセス

			$ telnet 192.168.1.1

1. ログイン
    * username : operatoor
    * password : \<none>
1. コンフィグレーションコマンドモードで実行

			> enable
			# configure

1. VLAN定義

			(config)# vlan <VLAN id>
			(config-vlan)# exit

	VLAN id　の値は、100,200,300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500,1600を入力した。

1. インスタンス作成

			(config)# openflow openflow-id <VSI id> virtual-switch
			(config-of)# controller controller-name cntl1 1 192.168.1.2 port 6653
			(config-of)# dpid <dpid>
			(config-of)# openflow-vlan <VLAN id>
			(config-of)# miss-action controller
			(config-of)# enable
			(config-of)# exit

	VSI id は1,2,・・・,16、VLAN id は前述の16個、dpid　は、0000000000000001,0000000000000002,・・・,0000000000000016の16個をそれぞれ入力した。

			(config-of)# openflow-vlan <VLAN id>

	を実行する際に、

			(config-of)# openflow-vlan 100
			openflow : Can't set because the OpenFlow instance is enabled.

	というエラーが出現する場合は、既に VSI (OpenFlow スイッチのインスタンス) がenable 状態になっているため、設定変更できないという旨のエラーであるため、

			(config-of)# no enable
			(config-of)# openflow-vlan <VLAN id>
			(config-of)# enable

	と入力することにより、VSIを一旦disableにしてから設定を行い、enable状態にする。  

1. 各VSIへのポートマップ

			(config)# interface range gigabitethernet 0/<from_port>-<to_port>
			(config-interface)# switchport mode dot1q-tunnel
			(config-interface)# switchport access vlan <VLAN id>

	今回VSIは16個であり、実機のポートは48個であったので、各VSIに3ポートずつ（VLAN ID 100 に、1,2,3番ポート）マップした。

1. 設定の保存

			(config)# save


## デモ（使い方）

### デモの内容
ユーザが VM を作成し、起動するまでの設定・操作方法を記す。
### 実機スイッチの接続
1番ポートと11番ポートが繋がるように、ケーブルを接続する。
### Controllerの使い方

1. 物理ネットワークの接続 （デフォルトスライス[default.sh](https://github.com/handai-trema/IaaS-nist/tree/master/default.sh)の設定を変更すれば以下は自由でよい）
	* マネージメントポートにコントローラを接続
	* 11番ポートにVMマネージャーを接続
	* 1番ポートにユーザー端末を接続
1. Virtualbox を起動
1. ID:ensyuu2 / Password:ensyuu2 でログイン
1. GitHub から Controller のファイル一式を Clone し、 master ブランチへ移動
1. スイッチ接続用ネットワークへの接続
1. 既存のtremaのファイルの変更
	統計情報取得のためにハンドラを設定したファイルに変更する。

			$ bundle install --binstubs

	を実行して作成される`/.rvm/gems/ruby-2.2.5/gems/trema-0.9.0/lib/trema/controller.rb `を`IaaS-nist/trema`配下にある[controller.rb](https://github.com/handai-trema/IaaS-nist/tree/master/trema/controller.rb) に変更する。

1. telnet 実行

			$ telnet 192.168.1.1

1. ログイン
	* username : operatoor
	* password : \<none>
1. コンフィグレーションコマンドモードで実行

			> enable
			# configure

1. ~/IaaS-nist/ に移動し、以下のコマンドを実行して Controller を起動

			$ ./bin/trema run ./lib/routing_switch_nist.rb  -- --slicing

1. 別ターミナルを起動し、~/IaaS-nist/にて以下のコマンドを実行し、デフォルトスライスを設定

			$ sh default.sh

1. 別ターミナルを起動し、~/IaaS-nist/にて以下のコマンドを実行し、トポロジ情報表示のためのサーバーを起動

			$ sh ./output/server.sh

1. ブラウザを起動し、`http://localhost:8080/output/`にアクセスすることで、トポロジ状態を確認できる。


### ユーザーのWebインターフェースの使い方

1. スイッチの1番ポートに接続
1. IP,MACアドレスの設定
    * IPアドレス：192.168.1.6
    * MACアドレス：08:00:27:74:6d:e2
1. Webページへアクセス
	* ユーザのPCからWebブラウザで以下のURLを入力すると、IaaSログインページヘアクセスできる。
	


### VMマネージャーの使い方

1. スイッチの11番ポートに接続
1. IP,MACアドレスの設定
    * IPアドレス：192.168.1.100
    * MACアドレス：08:00:27:74:6d:e1
1. Dockerが利用できるPCならば利用可能
1. /WebInterface/iaas-systemにて以下のコマンドを実行することでHTTPサーバが立ち上がる
```
	$ node VMmanager.js
```
1. 'http://(HTTPサーバを立ち上げた端末のIP):8174'でWebページにアクセス可能
1. あとはイベントに基づいたスクリプトが起動することでコンテナの管理が可能

 
### 使用例


