#!/bin/bash

# 功能选择菜单函数
show_menu() {
    clear
    echo "请选择你要执行的操作:"
    echo "1) 安装并启动 Shaicoin 节点"
    echo "2) 创建钱包"
    echo "3) 启动挖矿节点 (会关闭临时节点)"
    echo "4) 查询当前收益"
    echo "5) 查看节点日志"
    echo "6) 卸载 Shaicoin (不删除依赖)"
    echo "0) 退出"
    read -rp "输入数字选择操作: " choice
}

install_and_start_node() {
    echo "安装依赖..."
    sudo apt update
    sudo apt install -y build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 libevent-dev libboost-dev libsqlite3-dev

    echo "克隆并编译 Shaicoin 代码..."
    git clone https://github.com/shaicoin/shaicoin.git
    cd shaicoin || exit
    ./autogen.sh
    ./configure
    make -j8

    echo "启动节点..."
    ./src/shaicoind -addnode=51.161.117.199:42069 -addnode=139.60.161.14:42069 -addnode=149.50.101.189:21026 -addnode=3.21.125.80:42069 &
    
    echo "临时启动节点..."
    ./src/shaicoind -addnode=51.161.117.199:42069 -addnode=139.60.161.14:42069 &
    
    echo "Shaicoin 节点已成功启动。"
    read -rp "按回车返回主菜单..."  
}

create_wallet() {
    if ! pgrep -x "shaicoind" > /dev/null; then
        echo "没有找到正在运行的节点，请先安装并启动 Shaicoin 节点。"
        read -rp "按回车返回主菜单..."
        return
    fi

    echo "创建钱包..."
    ./src/shaicoin-cli createwallet "my_wallet"
    ./src/shaicoin-cli loadwallet "my_wallet"
    WALLET_ADDRESS=$(./src/shaicoin-cli getnewaddress)

    echo "你的钱包地址是: $WALLET_ADDRESS"
    read -rp "按回车返回主菜单..."
}

start_mining() {
    # 首先关闭临时节点
    TEMP_PID=$(pgrep shaicoind)
    if [[ -n $TEMP_PID ]]; then
        echo "关闭正在运行的临时节点..."
        kill $TEMP_PID
        sleep 5
    else
        echo "没有找到正在运行的临时节点。"
    fi

    if [[ ! -d ~/.shaicoin/wallets ]]; then
        echo "没有找到钱包，请先运行 '创建钱包' 选项。"
        read -rp "按回车返回主菜单..."
        return
    fi

    # 获取钱包地址
    WALLET_ADDRESS=$(./src/shaicoin-cli getnewaddress)

    echo "启动挖矿节点..."
    ./src/shaicoind -mine -moneyplz=$WALLET_ADDRESS -addnode=51.161.117.199:42069 -addnode=139.60.161.14:42069 -addnode=149.50.101.189:21026 -addnode=3.21.125.80:42069 &

    echo "挖矿节点启动成功。"
    read -rp "按回车返回主菜单..."
}

query_rewards() {
    if [[ ! -d ~/.shaicoin/wallets ]]; then
        echo "没有找到钱包，请先运行 '创建钱包' 选项。"
        read -rp "按回车返回主菜单..."
        return
    fi

    echo "查询当前收益..."
    ./src/shaicoin-cli getwalletinfo
    read -rp "按回车返回主菜单..."
}

view_logs() {
    LOG_FILE=~/.shaicoin/debug.log

    if [[ -f $LOG_FILE ]]; then
        echo "显示最新日志记录:"
        tail -n 50 "$LOG_FILE"
    else
        echo "日志文件不存在。"
    fi

    read -rp "按回车返回主菜单..."
}

uninstall_shaicoin() {
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
            start_mining  # 新增启动挖矿节点功能，同时关闭临时节点
            ;;
        4)
            query_rewards
            ;;
        5)
            view_logs  # 查看日志功能
            ;;
        6)
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
