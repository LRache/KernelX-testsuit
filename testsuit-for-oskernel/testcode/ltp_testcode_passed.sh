#!/glibc/busybox sh

cd ./ltp/testcases/bin

set -ex
./abort01
./abs01
./alarm02
./alarm03
./alarm05
./alarm06
./alarm07

./brk01
./brk02

./chdir04

./chmod01

./chown01
./chown02
./chown05

./clone01
./clone02
./clone03
# ./clone04
./clone05
./clone06
./clone07
./clone08
./clone301
./clone302
./close02
./close_range02

./dup01
./dup02
./dup03
./dup04
./dup06
./dup07
./dup201
./dup202
./dup203
./dup204
./dup205
./dup206
./dup207
./dup3_01
./dup3_02

./execl01
./execle01
./execlp01
./execv01
./execve01
./execve02
./execve03
./execve05
./execve06
./execveat01
./execvp01

./exit01
./exit02

./exit_group01

./fchdir02

./fchmod01
./fchmod02
./fchmod03
./fchmod04
./fchmod05
./fchmodat01
./fchmodat02
./fchown01
./fchown02
./fchown03
./fchown05
# ./fchownat01

./fork01
./fork03
./fork04
./fork05
./fork07
./fork08
./fork09
./fork10

./getegid01
./getegid02
./geteuid01
./geteuid02

./getgid01
./getgid03
./getgroups01
./getgroups03

./getpgid01
./getpgid02
./getpgrp01
./getpid01
./getpid02
./getppid01
./getppid02

./getrandom01
./getrandom02
./getrandom03
./getrandom04
./getrandom05

./getresgid01
./getresgid02
./getresgid03
./getresuid01
./getresuid02
./getresuid03

./getuid01
./getuid03

./uname01
./uname02
./uname04

./wait01
./wait02
./wait401
./wait402
./wait403

./waitpid01
./waitpid03
./waitpid04
./waitpid06
./waitpid07
./waitpid09
./waitpid10
./waitpid11
./waitpid12

./write01
./write02
./write03
./write05
./write06
./writev01
./writev02
./writev05
./writev06
