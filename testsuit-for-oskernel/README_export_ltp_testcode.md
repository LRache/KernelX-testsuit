# export_ltp_testcode.py

`export_ltp_testcode.py` 用于读取 `ltp_test_status.csv`，并根据指定的架构和 libc
环境导出可直接运行的 LTP 测试脚本。

生成的脚本会保留 LTP 的基础运行头：

```sh
#!/glibc/busybox sh

cd ./ltp/testcases/bin

export LTPROOT=../..

set -ex
```

头部之后，每个被导出的测试都会写成普通命令，例如：

```sh
./abort01
```

导出的脚本不会包含测试状态注释。

## CSV 格式

默认输入文件为：

```text
ltp_test_status.csv
```

必须包含以下列：

```csv
name,riscv_glibc,riscv_musl,loongarch_glibc,loongarch_musl
```

`name` 是不带 `./` 前缀的 LTP 测试名。其余环境列用于记录该测试在对应环境下的状态。

## 状态规则

脚本只会导出指定状态前缀的测试：

| 参数 | 导出的状态 |
| --- | --- |
| `--passed` | `PASS`、`PASS: ...` |
| `--half` | `PASS`、`PASS: ...`、`HALF`、`HALF: ...` |
| `--test` | `TEST`、`TEST: ...` |

以下状态不会被导出：

```text
FAILED...
KILLED...
空状态
```

## 环境选择

`--env` 可以指定单个环境，也可以指定一个架构组。

单个环境：

```text
riscv_glibc
riscv_musl
loongarch_glibc
loongarch_musl
```

架构组：

```text
riscv
loongarch
```

`--env riscv` 会同时导出 `riscv_glibc` 和 `riscv_musl`。

`--env loongarch` 会同时导出 `loongarch_glibc` 和 `loongarch_musl`。

## 默认输出路径

| 环境 | 输出文件 |
| --- | --- |
| `riscv_glibc` | `testcode-rv/ltp_testcode_glibc.sh` |
| `riscv_musl` | `testcode-rv/ltp_testcode_musl.sh` |
| `loongarch_glibc` | `testcode-la/ltp_testcode_glibc.sh` |
| `loongarch_musl` | `testcode-la/ltp_testcode_musl.sh` |

glibc 环境默认使用：

```sh
#!/glibc/busybox sh
```

musl 环境默认使用：

```sh
#!/musl/busybox sh
```

## 使用示例

导出 RISC-V 下 glibc 和 musl 的全部完全通过测试：

```sh
./export_ltp_testcode.py --env riscv --passed
```

导出 LoongArch 下 glibc 和 musl 的 `PASS` 与 `HALF` 测试：

```sh
./export_ltp_testcode.py --env loongarch --half
```

只导出 RISC-V musl 中标记为 `TEST` 的测试：

```sh
./export_ltp_testcode.py --env riscv_musl --test
```

将单个环境导出到自定义文件：

```sh
./export_ltp_testcode.py --env riscv_glibc --passed --output /tmp/ltp_testcode.sh
```

将一个架构组导出到自定义目录：

```sh
./export_ltp_testcode.py --env riscv --passed --output /tmp/ltp-export-riscv
```

这会生成：

```text
/tmp/ltp-export-riscv/ltp_testcode_glibc.sh
/tmp/ltp-export-riscv/ltp_testcode_musl.sh
```

只预览生成内容，不写入文件：

```sh
./export_ltp_testcode.py --env riscv_glibc --passed --dry-run
```

覆盖输出文件前创建带时间戳的备份：

```sh
./export_ltp_testcode.py --env riscv --half --backup
```

只有显式传入 `--backup` 时才会创建备份。

## 参数说明

| 参数 | 含义 |
| --- | --- |
| `--env` | 必填。指定单个环境或架构组。 |
| `--passed` | 只导出 `PASS...` 状态。 |
| `--half` | 导出 `PASS...` 和 `HALF...` 状态。 |
| `--test` | 只导出 `TEST...` 状态。 |
| `--csv` | 指定输入 CSV 路径，默认是 `ltp_test_status.csv`。 |
| `--output` | 单环境导出时表示输出文件；架构组导出时表示输出目录。 |
| `--busybox` | 覆盖生成脚本中的 busybox 路径。 |
| `--backup` | 覆盖输出文件前创建带时间戳的备份。 |
| `--dry-run` | 打印生成内容，不写入文件。 |
