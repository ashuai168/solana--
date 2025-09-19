# 自定义 Solana 靓号地址生成器

使用您选择的起始或结束文本生成自定义 Solana 钱包地址。采用 Rust 语言构建，可实现高性能生成和简洁的 Web 界面。


一键命令：./main.sh

## 🔒 安全与隐私

**此工具优先考虑您的安全：**
- ✅ **无需数据存储** - 私钥永远不会保存到磁盘
- ✅ **无需服务器日志记录** - 地址和私钥永远不会被记录
- ✅ **无需外部 API** - 所有内容都在您的本地计算机上运行
- ✅ **无需模拟/演示数据** - 所有地址均以加密方式生成
- ✅ **100% 开源** - 自行审核代码

**安全审核结果：**
- 不使用 localStorage、sessionStorage 或 Cookie
- 无需文件写入或数据库连接
- 私钥仅存在于内存中并立即显示
- 服务器日志仅包含尝试次数，绝不会包含敏感数据

## 功能

- 🚀 **快速生成** - 多线程 Rust 实现
- 🎯 **自定义模式** - 选择任意文本作为地址前缀或后缀
- 🌐 **Web 界面** - 基于浏览器，用户友好界面
- 🔐 **完全本地化** - 在您自己的机器上运行所有内容
- 📊 **实时进度** - 生成过程中实时显示钱包计数器

## 安装

### 先决条件

1. **Rust**（用于构建生成器）
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

2. **Python 3**（用于 Web 服务器）
```bash
python3 --version # 版本号应为 3.7 及以上
```

3. **Flask**（Python Web 框架）
```bash
pip install flask flask-cors
```

### 构建项目

1. 克隆代码库：
```bash
git clone https://github.com/yourusername/custom-crypto-addresses.git
cd custom-crypto-addresses
```

2. 构建 Rust 生成器：
```bash
cargo build --release
```

这将在 `target/release/` 目录中创建优化的二进制文件。

## 使用方法

### 选项 1：Web 界面（推荐）

1. 启动 Web 服务器：
```bash

python3 server.py

```

2. 打开浏览器并导航至：
```
http://localhost:8080
```

3. 输入您想要的自定义文本，然后点击“生成自定义地址”。

4. **重要提示：**立即复制并保存您的私钥！私钥只会显示一次。

### 选项 2：命令行

直接从终端运行生成器：

```bash
# 生成 5 个以“moon”结尾的地址
./target/release/solana-generator moon 5 后缀

# 生成 3 个以“sol”开头的地址
./target/release/solana-generator sol 3 前缀
```

**输出格式 (JSON)：**
```json
{
"type": "found",
"address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosmoon",
"private_key": "base58_private_key_here",
"attempts": 1234567
}
```

## 工作原理

1. **加密生成**：使用 `solana-sdk` 生成真实的密钥对
2. **模式匹配**：检查每个生成的地址是否符合您的模式。
3. **多线程**：利用所有 CPU 核心进行并行生成。
4. **流式更新**：每 10,000 次尝试发送一次进度更新。
5. **双生成**：同时创建前缀和后缀版本。

### 性能

- **短模式（1-3 个字符）**：通常几秒钟内即可找到。
- **中等模式（4 个字符）**：通常需要 10-30 秒。
- **长模式（5 个以上字符）**：可能需要几分钟。
- **前缀 vs 后缀**：前缀通常更难找到。

**注意：**每增加一个字符，难度都会呈指数级增长。

## 技术细节

### 架构

```
┌────────────┐ ┌────────────┐ ┌──────────────┐
│ 浏览器 │────▶│ Flask 服务器│────▶│ Rust 生成器│
│ (UI/显示)│◀────│ (路由器) │◀────│ (快速生成) │
└──────────────┘ └──────────────┘ └──────────────┘
SSE 流子进程 JSON 输出
```

### 文件结构

```
custom-crypto-addresses/
├── src/
│ ├── solana_generator.rs # 主生成器（无文件 I/O）
│ ├── ethereum_generator.rs # 以太坊版本（未使用）
│ ├── main.rs # 旧版本CLI 版本（Web 未使用）
│ └── ethereum.rs # 旧 CLI 版本（Web 未使用）
├── web/
│ └── index.html # Web 界面
├── server.py # Flask Web 服务器
├── Cargo.toml # Rust 依赖项
└── README.md # 此文件
```

### 依赖项

**Rust:**
- `solana-sdk` - Solana 密钥对生成
- `bs58` - Base58 编码
- `serde_json` - JSON 输出
- `rand` - 随机数生成

**Python:**
- `flask` - Web 框架
- `flask-cors` - CORS 支持

## 故障排除

### 端口已被使用
如果 8080 端口繁忙：
```bash
# 检查哪些程序正在使用 8080 端口
lsof -i :8080

# 使用其他端口
python server.py # 然后在 server.py 中修改端口
```

### 生成速度慢
- 较短的模式更容易被找到
- 后缀模式通常比前缀模式更快
- 关闭其他 CPU 密集型应用程序
- 使用 `--release` 标志构建以优化性能

### 浏览器未更新
- 强制刷新页面 (Cmd+Shift+R 或 Ctrl+Shift+F5)
- 检查浏览器控制台是否有错误 (F12)
- 确保 JavaScript 已启用

## 安全注意事项

1. **立即保存私钥** - 私钥仅显示一次
2. **切勿共享私钥** - 任何拥有私钥的人都拥有钱包
3. **本地运行** - 不要将托管版本用于真实钱包
4. **验证源代码** - 在生成有价值的钱包之前进行审核
5. **先测试** - 在生成重要地址之前先尝试测试模式

## 贡献

欢迎贡献！请确保：
- 无数据持久化机制
- 无外部 API 调用
- 向用户提供清晰的安全警告
- 遵循“无存储”原则

## 许可证

MIT 许可证 - 详情请参阅许可证文件

## 免责声明

此工具生成真实的加密货币钱包。作者不对以下情况负责：
- 私钥丢失
- 因密钥泄露导致资金被盗
- 任何财务损失

**使用风险自负。请务必安全保存您的私钥。**
