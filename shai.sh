#!/bin/bash

# 功能选择菜单函数
show_menu() {
    clear
    echo "==== Shaicoin 一键管理脚本 ===="
    echo "脚本作者推特: https://x.com/BtcK241918"
    echo "请选择你要执行的操作:"
    echo "1) 安装并启动 Shaicoin 节点"
    echo "2) 创建钱包"
    echo "3) 启动挖矿节点"
    echo "4) 启动临时节点"
    echo "5) 查看余额"
    echo "6) 查看节点日志"
    echo "7) 卸载 Shaicoin (不删除依赖)"
    echo "0) 退出"
    read -rp "输入数字选择操作: " choice
}

install_and_start_node() {
    echo "安装依赖..."
    sudo apt update
    sudo apt install -y build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 libevent-dev libboost-dev libsqlite3-dev jq

    echo "克隆并编译 Shaicoin 代码..."
    git clone https://github.com/shaicoin/shaicoin.git ~/shaicoin
    cd ~/shaicoin || exit
    ./autogen.sh
    ./configure
    make -j8

    echo "启动节点..."
    ~/shaicoin/src/shaicoind -addnode=51.161.117.199:42069 -addnode=139.60.161.14:42069 -addnode=149.50.101.189:21026 -addnode=3.21.125.80:42069 &

    echo "临时启动节点..."
    ~/shaicoin/src/shaicoind -addnode=51.161.117.199:42069 -addnode=139.60.161.14:42069 &

    echo "Shaicoin 节点已成功启动。"
    read -rp "按回车返回主菜单..."
}

create_wallet() {
    cd ~/shaicoin || exit
    if ! pgrep -x "shaicoind" > /dev/null; then
        echo "没有找到正在运行的节点，请先安装并启动 Shaicoin 节点。"
        read -rp "按回车返回主菜单..."
        return
    fi

    read -rp "输入钱包名称: " wallet_name
    if [ -d "$HOME/.shaicoin/wallets/$wallet_name" ]; then
        echo "钱包 \"$wallet_name\" 已经存在，请使用其他名称。"
        read -rp "按回车返回主菜单..."
        return
    fi

    echo "创建钱包..."
    ./src/shaicoin-cli createwallet "$wallet_name"
    echo "加载钱包..."
    ./src/shaicoin-cli loadwallet "$wallet_name"
    WALLET_ADDRESS=$(./src/shaicoin-cli getnewaddress)

    echo "你的钱包地址是: $WALLET_ADDRESS"
    read -rp "按回车返回主菜单..."
}

start_mining() {
    cd ~/shaicoin || exit
    echo "输入钱包地址以启动挖矿: "
    read -rp "钱包地址: " mining_address

    echo "启动挖矿节点..."
    ~/shaicoin/src/shaicoind -addnode=51.161.117.199:42869 -addnode=139.60.161.14:42069 -addnode=149.50.101.189:21026 -addnode=3.21.125.80:42069 -moneyplz="$mining_address" &

    echo "挖矿节点启动成功。"
    read -rp "按回车返回主菜单..."
}

start_temp_node() {
    echo "启动临时节点..."
    ~/shaicoin/src/shaicoind -addnode=51.161.117.199:42069 -addnode=139.60.161.14:42069 &
    echo "临时节点已成功启动。"
    read -rp "按回车返回主菜单..."
}

view_balance() {
    cd ~/shaicoin || exit

    read -rp "输入要加载的钱包名称: " wallet_name
    
    # 检查钱包是否已经加载
    LOADED_WALLETS=$(./src/shaicoin-cli listwallets)

    if echo "$LOADED_WALLETS" | grep -q "$wallet_name"; then
        echo "钱包 \"$wallet_name\" 已经加载."
    else
        echo "加载钱包..."
        ./src/shaicoin-cli loadwallet "$wallet_name"
    fi

    echo "查看已加载的钱包..."
    LOADED_WALLETS=$(./src/shaicoin-cli listwallets)
    echo "已加载的钱包: $LOADED_WALLETS"

    echo "查询余额..."
    BALANCE=$(./src/shaicoin-cli getbalance)
    echo "当前余额: $BALANCE"

    read -rp "按回车返回主菜单..."
}

view_logs() {
    cd ~/shaicoin || exit
    echo "查看节点日志 (最后 50 行)..."
    LOG_FILE="$HOME/.shaicoin/debug.log"
    if [[ -f $LOG_FILE ]]; then
        tail -n 50 "$LOG_FILE"
    else
        echo "没有找到日志文件."
    fi
    read -rp "按回车返回主菜单..."
}

uninstall_shaicoin() {
    read -rp "警告: 卸载将删除所有相关文件，输入Y确认卸载: " confirm
    if [[ $confirm != "Y" ]]; then
        echo "取消卸载。"
        read -rp "按回车返回主菜单..."
        return
    fi

    echo "卸载 Shaicoin 并清除相关文件 (不删除依赖)..."

    SHAICOIN_PID=$(pgrep shaicoind)
    if [[ -n $SHAICOIN_PID ]]; then
        echo "关闭正在运行的 Shaicoin 节点..."
        kill $SHAICOIN_PID
        sleep 5
    else
        echo "没有找到正在运行的 Shaicoin 节点。"
    fi

    echo "删除 Shaicoin 相关文件..."
    rm -rf ~/shaicoin
    rm -rf ~/.shaicoin

    echo "Shaicoin 已成功卸载，相关文件已清除 (不删除依赖)。"
    read -rp "按回车返回主菜单..."
}

while true; do
    show_menu
    case $choice in
        1)
            install_and_start_node
            ;;
        2)
            create_wallet
            ;;
        3)
            start_mining
            ;;
        4)
            start_temp_node
            ;;
        5)
            view_balance
            ;;
        6)
            view_logs
            ;;
        7)
            uninstall_shaicoin
            ;;
        0)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效的选择，请重新运行脚本并选择有效选项。"
            ;;
    esac
done
