
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	bac78793          	addi	a5,a5,-1108 # 80005c10 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dc478793          	addi	a5,a5,-572 # 80000e72 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	324080e7          	jalr	804(ra) # 80002450 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	77a080e7          	jalr	1914(ra) # 800008b6 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	e86080e7          	jalr	-378(ra) # 80002056 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	1ee080e7          	jalr	494(ra) # 800023fa <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	55e080e7          	jalr	1374(ra) # 800007e4 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54c080e7          	jalr	1356(ra) # 800007e4 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	540080e7          	jalr	1344(ra) # 800007e4 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	536080e7          	jalr	1334(ra) # 800007e4 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1ba080e7          	jalr	442(ra) # 800024a6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	da2080e7          	jalr	-606(ra) # 800021e2 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32a080e7          	jalr	810(ra) # 80000794 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	ea678793          	addi	a5,a5,-346 # 80021318 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7e70713          	addi	a4,a4,-898 # 80000102 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054663          	bltz	a0,80000530 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088b63          	beqz	a7,800004f6 <printint+0x60>
    buf[i++] = '-';
    800004e4:	fe040793          	addi	a5,s0,-32
    800004e8:	973e                	add	a4,a4,a5
    800004ea:	02d00793          	li	a5,45
    800004ee:	fef70823          	sb	a5,-16(a4)
    800004f2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f6:	02e05763          	blez	a4,80000524 <printint+0x8e>
    800004fa:	fd040793          	addi	a5,s0,-48
    800004fe:	00e784b3          	add	s1,a5,a4
    80000502:	fff78913          	addi	s2,a5,-1
    80000506:	993a                	add	s2,s2,a4
    80000508:	377d                	addiw	a4,a4,-1
    8000050a:	1702                	slli	a4,a4,0x20
    8000050c:	9301                	srli	a4,a4,0x20
    8000050e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000512:	fff4c503          	lbu	a0,-1(s1)
    80000516:	00000097          	auipc	ra,0x0
    8000051a:	d60080e7          	jalr	-672(ra) # 80000276 <consputc>
  while(--i >= 0)
    8000051e:	14fd                	addi	s1,s1,-1
    80000520:	ff2499e3          	bne	s1,s2,80000512 <printint+0x7c>
}
    80000524:	70a2                	ld	ra,40(sp)
    80000526:	7402                	ld	s0,32(sp)
    80000528:	64e2                	ld	s1,24(sp)
    8000052a:	6942                	ld	s2,16(sp)
    8000052c:	6145                	addi	sp,sp,48
    8000052e:	8082                	ret
    x = -xx;
    80000530:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000534:	4885                	li	a7,1
    x = -xx;
    80000536:	bf9d                	j	800004ac <printint+0x16>

0000000080000538 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000538:	1101                	addi	sp,sp,-32
    8000053a:	ec06                	sd	ra,24(sp)
    8000053c:	e822                	sd	s0,16(sp)
    8000053e:	e426                	sd	s1,8(sp)
    80000540:	1000                	addi	s0,sp,32
    80000542:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000544:	00011797          	auipc	a5,0x11
    80000548:	ce07ae23          	sw	zero,-772(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054c:	00008517          	auipc	a0,0x8
    80000550:	acc50513          	addi	a0,a0,-1332 # 80008018 <etext+0x18>
    80000554:	00000097          	auipc	ra,0x0
    80000558:	02e080e7          	jalr	46(ra) # 80000582 <printf>
  printf(s);
    8000055c:	8526                	mv	a0,s1
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	024080e7          	jalr	36(ra) # 80000582 <printf>
  printf("\n");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	b6250513          	addi	a0,a0,-1182 # 800080c8 <digits+0x88>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	014080e7          	jalr	20(ra) # 80000582 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000576:	4785                	li	a5,1
    80000578:	00009717          	auipc	a4,0x9
    8000057c:	a8f72423          	sw	a5,-1400(a4) # 80009000 <panicked>
  for(;;)
    80000580:	a001                	j	80000580 <panic+0x48>

0000000080000582 <printf>:
{
    80000582:	7131                	addi	sp,sp,-192
    80000584:	fc86                	sd	ra,120(sp)
    80000586:	f8a2                	sd	s0,112(sp)
    80000588:	f4a6                	sd	s1,104(sp)
    8000058a:	f0ca                	sd	s2,96(sp)
    8000058c:	ecce                	sd	s3,88(sp)
    8000058e:	e8d2                	sd	s4,80(sp)
    80000590:	e4d6                	sd	s5,72(sp)
    80000592:	e0da                	sd	s6,64(sp)
    80000594:	fc5e                	sd	s7,56(sp)
    80000596:	f862                	sd	s8,48(sp)
    80000598:	f466                	sd	s9,40(sp)
    8000059a:	f06a                	sd	s10,32(sp)
    8000059c:	ec6e                	sd	s11,24(sp)
    8000059e:	0100                	addi	s0,sp,128
    800005a0:	8a2a                	mv	s4,a0
    800005a2:	e40c                	sd	a1,8(s0)
    800005a4:	e810                	sd	a2,16(s0)
    800005a6:	ec14                	sd	a3,24(s0)
    800005a8:	f018                	sd	a4,32(s0)
    800005aa:	f41c                	sd	a5,40(s0)
    800005ac:	03043823          	sd	a6,48(s0)
    800005b0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b4:	00011d97          	auipc	s11,0x11
    800005b8:	c8cdad83          	lw	s11,-884(s11) # 80011240 <pr+0x18>
  if(locking)
    800005bc:	020d9b63          	bnez	s11,800005f2 <printf+0x70>
  if (fmt == 0)
    800005c0:	040a0263          	beqz	s4,80000604 <printf+0x82>
  va_start(ap, fmt);
    800005c4:	00840793          	addi	a5,s0,8
    800005c8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005cc:	000a4503          	lbu	a0,0(s4)
    800005d0:	14050f63          	beqz	a0,8000072e <printf+0x1ac>
    800005d4:	4981                	li	s3,0
    if(c != '%'){
    800005d6:	02500a93          	li	s5,37
    switch(c){
    800005da:	07000b93          	li	s7,112
  consputc('x');
    800005de:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e0:	00008b17          	auipc	s6,0x8
    800005e4:	a60b0b13          	addi	s6,s6,-1440 # 80008040 <digits>
    switch(c){
    800005e8:	07300c93          	li	s9,115
    800005ec:	06400c13          	li	s8,100
    800005f0:	a82d                	j	8000062a <printf+0xa8>
    acquire(&pr.lock);
    800005f2:	00011517          	auipc	a0,0x11
    800005f6:	c3650513          	addi	a0,a0,-970 # 80011228 <pr>
    800005fa:	00000097          	auipc	ra,0x0
    800005fe:	5d6080e7          	jalr	1494(ra) # 80000bd0 <acquire>
    80000602:	bf7d                	j	800005c0 <printf+0x3e>
    panic("null fmt");
    80000604:	00008517          	auipc	a0,0x8
    80000608:	a2450513          	addi	a0,a0,-1500 # 80008028 <etext+0x28>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	f2c080e7          	jalr	-212(ra) # 80000538 <panic>
      consputc(c);
    80000614:	00000097          	auipc	ra,0x0
    80000618:	c62080e7          	jalr	-926(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061c:	2985                	addiw	s3,s3,1
    8000061e:	013a07b3          	add	a5,s4,s3
    80000622:	0007c503          	lbu	a0,0(a5)
    80000626:	10050463          	beqz	a0,8000072e <printf+0x1ac>
    if(c != '%'){
    8000062a:	ff5515e3          	bne	a0,s5,80000614 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000062e:	2985                	addiw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c783          	lbu	a5,0(a5)
    80000638:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063c:	cbed                	beqz	a5,8000072e <printf+0x1ac>
    switch(c){
    8000063e:	05778a63          	beq	a5,s7,80000692 <printf+0x110>
    80000642:	02fbf663          	bgeu	s7,a5,8000066e <printf+0xec>
    80000646:	09978863          	beq	a5,s9,800006d6 <printf+0x154>
    8000064a:	07800713          	li	a4,120
    8000064e:	0ce79563          	bne	a5,a4,80000718 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000652:	f8843783          	ld	a5,-120(s0)
    80000656:	00878713          	addi	a4,a5,8
    8000065a:	f8e43423          	sd	a4,-120(s0)
    8000065e:	4605                	li	a2,1
    80000660:	85ea                	mv	a1,s10
    80000662:	4388                	lw	a0,0(a5)
    80000664:	00000097          	auipc	ra,0x0
    80000668:	e32080e7          	jalr	-462(ra) # 80000496 <printint>
      break;
    8000066c:	bf45                	j	8000061c <printf+0x9a>
    switch(c){
    8000066e:	09578f63          	beq	a5,s5,8000070c <printf+0x18a>
    80000672:	0b879363          	bne	a5,s8,80000718 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000676:	f8843783          	ld	a5,-120(s0)
    8000067a:	00878713          	addi	a4,a5,8
    8000067e:	f8e43423          	sd	a4,-120(s0)
    80000682:	4605                	li	a2,1
    80000684:	45a9                	li	a1,10
    80000686:	4388                	lw	a0,0(a5)
    80000688:	00000097          	auipc	ra,0x0
    8000068c:	e0e080e7          	jalr	-498(ra) # 80000496 <printint>
      break;
    80000690:	b771                	j	8000061c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a2:	03000513          	li	a0,48
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	bd0080e7          	jalr	-1072(ra) # 80000276 <consputc>
  consputc('x');
    800006ae:	07800513          	li	a0,120
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bc4080e7          	jalr	-1084(ra) # 80000276 <consputc>
    800006ba:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006bc:	03c95793          	srli	a5,s2,0x3c
    800006c0:	97da                	add	a5,a5,s6
    800006c2:	0007c503          	lbu	a0,0(a5)
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	bb0080e7          	jalr	-1104(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ce:	0912                	slli	s2,s2,0x4
    800006d0:	34fd                	addiw	s1,s1,-1
    800006d2:	f4ed                	bnez	s1,800006bc <printf+0x13a>
    800006d4:	b7a1                	j	8000061c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d6:	f8843783          	ld	a5,-120(s0)
    800006da:	00878713          	addi	a4,a5,8
    800006de:	f8e43423          	sd	a4,-120(s0)
    800006e2:	6384                	ld	s1,0(a5)
    800006e4:	cc89                	beqz	s1,800006fe <printf+0x17c>
      for(; *s; s++)
    800006e6:	0004c503          	lbu	a0,0(s1)
    800006ea:	d90d                	beqz	a0,8000061c <printf+0x9a>
        consputc(*s);
    800006ec:	00000097          	auipc	ra,0x0
    800006f0:	b8a080e7          	jalr	-1142(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f4:	0485                	addi	s1,s1,1
    800006f6:	0004c503          	lbu	a0,0(s1)
    800006fa:	f96d                	bnez	a0,800006ec <printf+0x16a>
    800006fc:	b705                	j	8000061c <printf+0x9a>
        s = "(null)";
    800006fe:	00008497          	auipc	s1,0x8
    80000702:	92248493          	addi	s1,s1,-1758 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000706:	02800513          	li	a0,40
    8000070a:	b7cd                	j	800006ec <printf+0x16a>
      consputc('%');
    8000070c:	8556                	mv	a0,s5
    8000070e:	00000097          	auipc	ra,0x0
    80000712:	b68080e7          	jalr	-1176(ra) # 80000276 <consputc>
      break;
    80000716:	b719                	j	8000061c <printf+0x9a>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b5c080e7          	jalr	-1188(ra) # 80000276 <consputc>
      consputc(c);
    80000722:	8526                	mv	a0,s1
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b52080e7          	jalr	-1198(ra) # 80000276 <consputc>
      break;
    8000072c:	bdc5                	j	8000061c <printf+0x9a>
  if(locking)
    8000072e:	020d9163          	bnez	s11,80000750 <printf+0x1ce>
}
    80000732:	70e6                	ld	ra,120(sp)
    80000734:	7446                	ld	s0,112(sp)
    80000736:	74a6                	ld	s1,104(sp)
    80000738:	7906                	ld	s2,96(sp)
    8000073a:	69e6                	ld	s3,88(sp)
    8000073c:	6a46                	ld	s4,80(sp)
    8000073e:	6aa6                	ld	s5,72(sp)
    80000740:	6b06                	ld	s6,64(sp)
    80000742:	7be2                	ld	s7,56(sp)
    80000744:	7c42                	ld	s8,48(sp)
    80000746:	7ca2                	ld	s9,40(sp)
    80000748:	7d02                	ld	s10,32(sp)
    8000074a:	6de2                	ld	s11,24(sp)
    8000074c:	6129                	addi	sp,sp,192
    8000074e:	8082                	ret
    release(&pr.lock);
    80000750:	00011517          	auipc	a0,0x11
    80000754:	ad850513          	addi	a0,a0,-1320 # 80011228 <pr>
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	52c080e7          	jalr	1324(ra) # 80000c84 <release>
}
    80000760:	bfc9                	j	80000732 <printf+0x1b0>

0000000080000762 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000762:	1101                	addi	sp,sp,-32
    80000764:	ec06                	sd	ra,24(sp)
    80000766:	e822                	sd	s0,16(sp)
    80000768:	e426                	sd	s1,8(sp)
    8000076a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076c:	00011497          	auipc	s1,0x11
    80000770:	abc48493          	addi	s1,s1,-1348 # 80011228 <pr>
    80000774:	00008597          	auipc	a1,0x8
    80000778:	8c458593          	addi	a1,a1,-1852 # 80008038 <etext+0x38>
    8000077c:	8526                	mv	a0,s1
    8000077e:	00000097          	auipc	ra,0x0
    80000782:	3c2080e7          	jalr	962(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000786:	4785                	li	a5,1
    80000788:	cc9c                	sw	a5,24(s1)
}
    8000078a:	60e2                	ld	ra,24(sp)
    8000078c:	6442                	ld	s0,16(sp)
    8000078e:	64a2                	ld	s1,8(sp)
    80000790:	6105                	addi	sp,sp,32
    80000792:	8082                	ret

0000000080000794 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000794:	1141                	addi	sp,sp,-16
    80000796:	e406                	sd	ra,8(sp)
    80000798:	e022                	sd	s0,0(sp)
    8000079a:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079c:	100007b7          	lui	a5,0x10000
    800007a0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a4:	f8000713          	li	a4,-128
    800007a8:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ac:	470d                	li	a4,3
    800007ae:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ba:	469d                	li	a3,7
    800007bc:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c0:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	89458593          	addi	a1,a1,-1900 # 80008058 <digits+0x18>
    800007cc:	00011517          	auipc	a0,0x11
    800007d0:	a7c50513          	addi	a0,a0,-1412 # 80011248 <uart_tx_lock>
    800007d4:	00000097          	auipc	ra,0x0
    800007d8:	36c080e7          	jalr	876(ra) # 80000b40 <initlock>
}
    800007dc:	60a2                	ld	ra,8(sp)
    800007de:	6402                	ld	s0,0(sp)
    800007e0:	0141                	addi	sp,sp,16
    800007e2:	8082                	ret

00000000800007e4 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e4:	1101                	addi	sp,sp,-32
    800007e6:	ec06                	sd	ra,24(sp)
    800007e8:	e822                	sd	s0,16(sp)
    800007ea:	e426                	sd	s1,8(sp)
    800007ec:	1000                	addi	s0,sp,32
    800007ee:	84aa                	mv	s1,a0
  push_off();
    800007f0:	00000097          	auipc	ra,0x0
    800007f4:	394080e7          	jalr	916(ra) # 80000b84 <push_off>

  if(panicked){
    800007f8:	00009797          	auipc	a5,0x9
    800007fc:	8087a783          	lw	a5,-2040(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000800:	10000737          	lui	a4,0x10000
  if(panicked){
    80000804:	c391                	beqz	a5,80000808 <uartputc_sync+0x24>
    for(;;)
    80000806:	a001                	j	80000806 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080c:	0207f793          	andi	a5,a5,32
    80000810:	dfe5                	beqz	a5,80000808 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000812:	0ff4f513          	andi	a0,s1,255
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000081e:	00000097          	auipc	ra,0x0
    80000822:	406080e7          	jalr	1030(ra) # 80000c24 <pop_off>
}
    80000826:	60e2                	ld	ra,24(sp)
    80000828:	6442                	ld	s0,16(sp)
    8000082a:	64a2                	ld	s1,8(sp)
    8000082c:	6105                	addi	sp,sp,32
    8000082e:	8082                	ret

0000000080000830 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000830:	00008797          	auipc	a5,0x8
    80000834:	7d87b783          	ld	a5,2008(a5) # 80009008 <uart_tx_r>
    80000838:	00008717          	auipc	a4,0x8
    8000083c:	7d873703          	ld	a4,2008(a4) # 80009010 <uart_tx_w>
    80000840:	06f70a63          	beq	a4,a5,800008b4 <uartstart+0x84>
{
    80000844:	7139                	addi	sp,sp,-64
    80000846:	fc06                	sd	ra,56(sp)
    80000848:	f822                	sd	s0,48(sp)
    8000084a:	f426                	sd	s1,40(sp)
    8000084c:	f04a                	sd	s2,32(sp)
    8000084e:	ec4e                	sd	s3,24(sp)
    80000850:	e852                	sd	s4,16(sp)
    80000852:	e456                	sd	s5,8(sp)
    80000854:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000856:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085a:	00011a17          	auipc	s4,0x11
    8000085e:	9eea0a13          	addi	s4,s4,-1554 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000862:	00008497          	auipc	s1,0x8
    80000866:	7a648493          	addi	s1,s1,1958 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086a:	00008997          	auipc	s3,0x8
    8000086e:	7a698993          	addi	s3,s3,1958 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000872:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000876:	02077713          	andi	a4,a4,32
    8000087a:	c705                	beqz	a4,800008a2 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087c:	01f7f713          	andi	a4,a5,31
    80000880:	9752                	add	a4,a4,s4
    80000882:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000886:	0785                	addi	a5,a5,1
    80000888:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088a:	8526                	mv	a0,s1
    8000088c:	00002097          	auipc	ra,0x2
    80000890:	956080e7          	jalr	-1706(ra) # 800021e2 <wakeup>
    
    WriteReg(THR, c);
    80000894:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000898:	609c                	ld	a5,0(s1)
    8000089a:	0009b703          	ld	a4,0(s3)
    8000089e:	fcf71ae3          	bne	a4,a5,80000872 <uartstart+0x42>
  }
}
    800008a2:	70e2                	ld	ra,56(sp)
    800008a4:	7442                	ld	s0,48(sp)
    800008a6:	74a2                	ld	s1,40(sp)
    800008a8:	7902                	ld	s2,32(sp)
    800008aa:	69e2                	ld	s3,24(sp)
    800008ac:	6a42                	ld	s4,16(sp)
    800008ae:	6aa2                	ld	s5,8(sp)
    800008b0:	6121                	addi	sp,sp,64
    800008b2:	8082                	ret
    800008b4:	8082                	ret

00000000800008b6 <uartputc>:
{
    800008b6:	7179                	addi	sp,sp,-48
    800008b8:	f406                	sd	ra,40(sp)
    800008ba:	f022                	sd	s0,32(sp)
    800008bc:	ec26                	sd	s1,24(sp)
    800008be:	e84a                	sd	s2,16(sp)
    800008c0:	e44e                	sd	s3,8(sp)
    800008c2:	e052                	sd	s4,0(sp)
    800008c4:	1800                	addi	s0,sp,48
    800008c6:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008c8:	00011517          	auipc	a0,0x11
    800008cc:	98050513          	addi	a0,a0,-1664 # 80011248 <uart_tx_lock>
    800008d0:	00000097          	auipc	ra,0x0
    800008d4:	300080e7          	jalr	768(ra) # 80000bd0 <acquire>
  if(panicked){
    800008d8:	00008797          	auipc	a5,0x8
    800008dc:	7287a783          	lw	a5,1832(a5) # 80009000 <panicked>
    800008e0:	c391                	beqz	a5,800008e4 <uartputc+0x2e>
    for(;;)
    800008e2:	a001                	j	800008e2 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e4:	00008717          	auipc	a4,0x8
    800008e8:	72c73703          	ld	a4,1836(a4) # 80009010 <uart_tx_w>
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	71c7b783          	ld	a5,1820(a5) # 80009008 <uart_tx_r>
    800008f4:	02078793          	addi	a5,a5,32
    800008f8:	02e79b63          	bne	a5,a4,8000092e <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	94c98993          	addi	s3,s3,-1716 # 80011248 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	70448493          	addi	s1,s1,1796 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	70490913          	addi	s2,s2,1796 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000914:	85ce                	mv	a1,s3
    80000916:	8526                	mv	a0,s1
    80000918:	00001097          	auipc	ra,0x1
    8000091c:	73e080e7          	jalr	1854(ra) # 80002056 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00093703          	ld	a4,0(s2)
    80000924:	609c                	ld	a5,0(s1)
    80000926:	02078793          	addi	a5,a5,32
    8000092a:	fee785e3          	beq	a5,a4,80000914 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000092e:	00011497          	auipc	s1,0x11
    80000932:	91a48493          	addi	s1,s1,-1766 # 80011248 <uart_tx_lock>
    80000936:	01f77793          	andi	a5,a4,31
    8000093a:	97a6                	add	a5,a5,s1
    8000093c:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000940:	0705                	addi	a4,a4,1
    80000942:	00008797          	auipc	a5,0x8
    80000946:	6ce7b723          	sd	a4,1742(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	ee6080e7          	jalr	-282(ra) # 80000830 <uartstart>
      release(&uart_tx_lock);
    80000952:	8526                	mv	a0,s1
    80000954:	00000097          	auipc	ra,0x0
    80000958:	330080e7          	jalr	816(ra) # 80000c84 <release>
}
    8000095c:	70a2                	ld	ra,40(sp)
    8000095e:	7402                	ld	s0,32(sp)
    80000960:	64e2                	ld	s1,24(sp)
    80000962:	6942                	ld	s2,16(sp)
    80000964:	69a2                	ld	s3,8(sp)
    80000966:	6a02                	ld	s4,0(sp)
    80000968:	6145                	addi	sp,sp,48
    8000096a:	8082                	ret

000000008000096c <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096c:	1141                	addi	sp,sp,-16
    8000096e:	e422                	sd	s0,8(sp)
    80000970:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000972:	100007b7          	lui	a5,0x10000
    80000976:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097a:	8b85                	andi	a5,a5,1
    8000097c:	cb91                	beqz	a5,80000990 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    8000097e:	100007b7          	lui	a5,0x10000
    80000982:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000986:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1e>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	916080e7          	jalr	-1770(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc2080e7          	jalr	-62(ra) # 8000096c <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00011497          	auipc	s1,0x11
    800009ba:	89248493          	addi	s1,s1,-1902 # 80011248 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	210080e7          	jalr	528(ra) # 80000bd0 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e68080e7          	jalr	-408(ra) # 80000830 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b2080e7          	jalr	690(ra) # 80000c84 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00025797          	auipc	a5,0x25
    800009fc:	60878793          	addi	a5,a5,1544 # 80026000 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2bc080e7          	jalr	700(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00011917          	auipc	s2,0x11
    80000a1c:	86890913          	addi	s2,s2,-1944 # 80011280 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1ae080e7          	jalr	430(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	24e080e7          	jalr	590(ra) # 80000c84 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	ae6080e7          	jalr	-1306(ra) # 80000538 <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	94aa                	add	s1,s1,a0
    80000a72:	757d                	lui	a0,0xfffff
    80000a74:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3a>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5e080e7          	jalr	-162(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x28>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f8a080e7          	jalr	-118(ra) # 80000a5a <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91c080e7          	jalr	-1764(ra) # 80000538 <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8cc080e7          	jalr	-1844(ra) # 80000538 <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8bc080e7          	jalr	-1860(ra) # 80000538 <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	874080e7          	jalr	-1932(ra) # 80000538 <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	fff6c793          	not	a5,a3
    80000e06:	9fb9                	addw	a5,a5,a4
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6da080e7          	jalr	1754(ra) # 80000582 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	81a080e7          	jalr	-2022(ra) # 800026d2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	d90080e7          	jalr	-624(ra) # 80005c50 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fdc080e7          	jalr	-36(ra) # 80001ea4 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88a080e7          	jalr	-1910(ra) # 80000762 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69a080e7          	jalr	1690(ra) # 80000582 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68a080e7          	jalr	1674(ra) # 80000582 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67a080e7          	jalr	1658(ra) # 80000582 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	77a080e7          	jalr	1914(ra) # 800026aa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	79a080e7          	jalr	1946(ra) # 800026d2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	cfa080e7          	jalr	-774(ra) # 80005c3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d08080e7          	jalr	-760(ra) # 80005c50 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	edc080e7          	jalr	-292(ra) # 80002e2c <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	56c080e7          	jalr	1388(ra) # 800034c4 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	516080e7          	jalr	1302(ra) # 80004476 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e0a080e7          	jalr	-502(ra) # 80005d72 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	cfe080e7          	jalr	-770(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	55e080e7          	jalr	1374(ra) # 80000538 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	00a7d513          	srli	a0,a5,0xa
    8000108c:	0532                	slli	a0,a0,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	77fd                	lui	a5,0xfffff
    800010b2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	15fd                	addi	a1,a1,-1
    800010b8:	00c589b3          	add	s3,a1,a2
    800010bc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010c0:	8952                	mv	s2,s4
    800010c2:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	438080e7          	jalr	1080(ra) # 80000538 <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	428080e7          	jalr	1064(ra) # 80000538 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3dc080e7          	jalr	988(ra) # 80000538 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	290080e7          	jalr	656(ra) # 80000538 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	280080e7          	jalr	640(ra) # 80000538 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	270080e7          	jalr	624(ra) # 80000538 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	260080e7          	jalr	608(ra) # 80000538 <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6d0080e7          	jalr	1744(ra) # 800009e4 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	182080e7          	jalr	386(ra) # 80000538 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	556080e7          	jalr	1366(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c8850513          	addi	a0,a0,-888 # 80008178 <digits+0x138>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	040080e7          	jalr	64(ra) # 80000538 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e2080e7          	jalr	1250(ra) # 800009e4 <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a34080e7          	jalr	-1484(ra) # 80000fac <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	54a080e7          	jalr	1354(ra) # 80000ae0 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	782080e7          	jalr	1922(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	adc080e7          	jalr	-1316(ra) # 80001094 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bbc50513          	addi	a0,a0,-1092 # 80008188 <digits+0x148>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f64080e7          	jalr	-156(ra) # 80000538 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bcc50513          	addi	a0,a0,-1076 # 800081a8 <digits+0x168>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f54080e7          	jalr	-172(ra) # 80000538 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3f6080e7          	jalr	1014(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	97e080e7          	jalr	-1666(ra) # 80000fac <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b8250513          	addi	a0,a0,-1150 # 800081c8 <digits+0x188>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	eea080e7          	jalr	-278(ra) # 80000538 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	69e080e7          	jalr	1694(ra) # 80000d28 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9aa080e7          	jalr	-1622(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	caa5                	beqz	a3,80001752 <copyin+0x70>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a01d                	j	8000172e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	018505b3          	add	a1,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	412585b3          	sub	a1,a1,s2
    80001716:	8552                	mv	a0,s4
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	610080e7          	jalr	1552(ra) # 80000d28 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001724:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	91c080e7          	jalr	-1764(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    if(n > len)
    80001746:	fc99f2e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	bf7d                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyin+0x76>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001770:	c6c5                	beqz	a3,80001818 <copyinstr+0xa8>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8a2a                	mv	s4,a0
    8000178a:	8b2e                	mv	s6,a1
    8000178c:	8bb2                	mv	s7,a2
    8000178e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6985                	lui	s3,0x1
    80001794:	a035                	j	800017c0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001796:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179c:	0017b793          	seqz	a5,a5
    800017a0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a4:	60a6                	ld	ra,72(sp)
    800017a6:	6406                	ld	s0,64(sp)
    800017a8:	74e2                	ld	s1,56(sp)
    800017aa:	7942                	ld	s2,48(sp)
    800017ac:	79a2                	ld	s3,40(sp)
    800017ae:	7a02                	ld	s4,32(sp)
    800017b0:	6ae2                	ld	s5,24(sp)
    800017b2:	6b42                	ld	s6,16(sp)
    800017b4:	6ba2                	ld	s7,8(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ba:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017be:	c8a9                	beqz	s1,80001810 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017c0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c4:	85ca                	mv	a1,s2
    800017c6:	8552                	mv	a0,s4
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	88a080e7          	jalr	-1910(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d0:	c131                	beqz	a0,80001814 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d2:	41790833          	sub	a6,s2,s7
    800017d6:	984e                	add	a6,a6,s3
    if(n > max)
    800017d8:	0104f363          	bgeu	s1,a6,800017de <copyinstr+0x6e>
    800017dc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017de:	955e                	add	a0,a0,s7
    800017e0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e4:	fc080be3          	beqz	a6,800017ba <copyinstr+0x4a>
    800017e8:	985a                	add	a6,a6,s6
    800017ea:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ec:	41650633          	sub	a2,a0,s6
    800017f0:	14fd                	addi	s1,s1,-1
    800017f2:	9b26                	add	s6,s6,s1
    800017f4:	00f60733          	add	a4,a2,a5
    800017f8:	00074703          	lbu	a4,0(a4)
    800017fc:	df49                	beqz	a4,80001796 <copyinstr+0x26>
        *dst = *p;
    800017fe:	00e78023          	sb	a4,0(a5)
      --max;
    80001802:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001806:	0785                	addi	a5,a5,1
    while(n > 0){
    80001808:	ff0796e3          	bne	a5,a6,800017f4 <copyinstr+0x84>
      dst++;
    8000180c:	8b42                	mv	s6,a6
    8000180e:	b775                	j	800017ba <copyinstr+0x4a>
    80001810:	4781                	li	a5,0
    80001812:	b769                	j	8000179c <copyinstr+0x2c>
      return -1;
    80001814:	557d                	li	a0,-1
    80001816:	b779                	j	800017a4 <copyinstr+0x34>
  int got_null = 0;
    80001818:	4781                	li	a5,0
  if(got_null){
    8000181a:	0017b793          	seqz	a5,a5
    8000181e:	40f00533          	neg	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1
    80001852:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	87ca0a13          	addi	s4,s4,-1924 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if (pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000188e:	16848493          	addi	s1,s1,360
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c86080e7          	jalr	-890(ra) # 80000538 <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1
    8000191e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001920:	00015997          	auipc	s3,0x15
    80001924:	7b098993          	addi	s3,s3,1968 # 800170d0 <tickslock>
    initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000194e:	16848493          	addi	s1,s1,360
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first)
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	eba7a783          	lw	a5,-326(a5) # 800088a0 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	cfa080e7          	jalr	-774(ra) # 800026ea <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ea07a023          	sw	zero,-352(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	a3a080e7          	jalr	-1478(ra) # 80003444 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
{
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e7278793          	addi	a5,a5,-398 # 800088a4 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a56080e7          	jalr	-1450(ra) # 8000151a <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a30080e7          	jalr	-1488(ra) # 8000151a <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e6080e7          	jalr	-1562(ra) # 8000151a <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8c080e7          	jalr	-372(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	51c90913          	addi	s2,s2,1308 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if (p->state == UNUSED)
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03a080e7          	jalr	58(ra) # 80000c84 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	022080e7          	jalr	34(ra) # 80000c84 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	c2258593          	addi	a1,a1,-990 # 800088b0 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6b4080e7          	jalr	1716(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	55058593          	addi	a1,a1,1360 # 80008200 <digits+0x1c0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54c50513          	addi	a0,a0,1356 # 80008210 <digits+0x1d0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	1a6080e7          	jalr	422(ra) # 80003e72 <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa6080e7          	jalr	-90(ra) # 80000c84 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  else if (n < 0)
    80001d12:	0204cc63          	bltz	s1,80001d4a <growproc+0x5a>
  p->sz = sz;
    80001d16:	1602                	slli	a2,a2,0x20
    80001d18:	9201                	srli	a2,a2,0x20
    80001d1a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d2c:	9e25                	addw	a2,a2,s1
    80001d2e:	1602                	slli	a2,a2,0x20
    80001d30:	9201                	srli	a2,a2,0x20
    80001d32:	1582                	slli	a1,a1,0x20
    80001d34:	9181                	srli	a1,a1,0x20
    80001d36:	6928                	ld	a0,80(a0)
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	6ce080e7          	jalr	1742(ra) # 80001406 <uvmalloc>
    80001d40:	0005061b          	sext.w	a2,a0
    80001d44:	fa69                	bnez	a2,80001d16 <growproc+0x26>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bfe1                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	9e25                	addw	a2,a2,s1
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	1582                	slli	a1,a1,0x20
    80001d52:	9181                	srli	a1,a1,0x20
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	668080e7          	jalr	1640(ra) # 800013be <uvmdealloc>
    80001d5e:	0005061b          	sext.w	a2,a0
    80001d62:	bf55                	j	80001d16 <growproc+0x26>

0000000080001d64 <fork>:
{
    80001d64:	7139                	addi	sp,sp,-64
    80001d66:	fc06                	sd	ra,56(sp)
    80001d68:	f822                	sd	s0,48(sp)
    80001d6a:	f426                	sd	s1,40(sp)
    80001d6c:	f04a                	sd	s2,32(sp)
    80001d6e:	ec4e                	sd	s3,24(sp)
    80001d70:	e852                	sd	s4,16(sp)
    80001d72:	e456                	sd	s5,8(sp)
    80001d74:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c20080e7          	jalr	-992(ra) # 80001996 <myproc>
    80001d7e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	e20080e7          	jalr	-480(ra) # 80001ba0 <allocproc>
    80001d88:	10050c63          	beqz	a0,80001ea0 <fork+0x13c>
    80001d8c:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d8e:	048ab603          	ld	a2,72(s5)
    80001d92:	692c                	ld	a1,80(a0)
    80001d94:	050ab503          	ld	a0,80(s5)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	7ba080e7          	jalr	1978(ra) # 80001552 <uvmcopy>
    80001da0:	04054863          	bltz	a0,80001df0 <fork+0x8c>
  np->sz = p->sz;
    80001da4:	048ab783          	ld	a5,72(s5)
    80001da8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dac:	058ab683          	ld	a3,88(s5)
    80001db0:	87b6                	mv	a5,a3
    80001db2:	058a3703          	ld	a4,88(s4)
    80001db6:	12068693          	addi	a3,a3,288
    80001dba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbe:	6788                	ld	a0,8(a5)
    80001dc0:	6b8c                	ld	a1,16(a5)
    80001dc2:	6f90                	ld	a2,24(a5)
    80001dc4:	01073023          	sd	a6,0(a4)
    80001dc8:	e708                	sd	a0,8(a4)
    80001dca:	eb0c                	sd	a1,16(a4)
    80001dcc:	ef10                	sd	a2,24(a4)
    80001dce:	02078793          	addi	a5,a5,32
    80001dd2:	02070713          	addi	a4,a4,32
    80001dd6:	fed792e3          	bne	a5,a3,80001dba <fork+0x56>
  np->trapframe->a0 = 0;
    80001dda:	058a3783          	ld	a5,88(s4)
    80001dde:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001de2:	0d0a8493          	addi	s1,s5,208
    80001de6:	0d0a0913          	addi	s2,s4,208
    80001dea:	150a8993          	addi	s3,s5,336
    80001dee:	a00d                	j	80001e10 <fork+0xac>
    freeproc(np);
    80001df0:	8552                	mv	a0,s4
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	d56080e7          	jalr	-682(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001dfa:	8552                	mv	a0,s4
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	e88080e7          	jalr	-376(ra) # 80000c84 <release>
    return -1;
    80001e04:	597d                	li	s2,-1
    80001e06:	a059                	j	80001e8c <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e08:	04a1                	addi	s1,s1,8
    80001e0a:	0921                	addi	s2,s2,8
    80001e0c:	01348b63          	beq	s1,s3,80001e22 <fork+0xbe>
    if (p->ofile[i])
    80001e10:	6088                	ld	a0,0(s1)
    80001e12:	d97d                	beqz	a0,80001e08 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e14:	00002097          	auipc	ra,0x2
    80001e18:	6f4080e7          	jalr	1780(ra) # 80004508 <filedup>
    80001e1c:	00a93023          	sd	a0,0(s2)
    80001e20:	b7e5                	j	80001e08 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e22:	150ab503          	ld	a0,336(s5)
    80001e26:	00002097          	auipc	ra,0x2
    80001e2a:	858080e7          	jalr	-1960(ra) # 8000367e <idup>
    80001e2e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e32:	4641                	li	a2,16
    80001e34:	158a8593          	addi	a1,s5,344
    80001e38:	158a0513          	addi	a0,s4,344
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	fda080e7          	jalr	-38(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e44:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e48:	8552                	mv	a0,s4
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e3a080e7          	jalr	-454(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e52:	0000f497          	auipc	s1,0xf
    80001e56:	46648493          	addi	s1,s1,1126 # 800112b8 <wait_lock>
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d74080e7          	jalr	-652(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e64:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e1a080e7          	jalr	-486(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e72:	8552                	mv	a0,s4
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d5c080e7          	jalr	-676(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e7c:	478d                	li	a5,3
    80001e7e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e82:	8552                	mv	a0,s4
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e00080e7          	jalr	-512(ra) # 80000c84 <release>
}
    80001e8c:	854a                	mv	a0,s2
    80001e8e:	70e2                	ld	ra,56(sp)
    80001e90:	7442                	ld	s0,48(sp)
    80001e92:	74a2                	ld	s1,40(sp)
    80001e94:	7902                	ld	s2,32(sp)
    80001e96:	69e2                	ld	s3,24(sp)
    80001e98:	6a42                	ld	s4,16(sp)
    80001e9a:	6aa2                	ld	s5,8(sp)
    80001e9c:	6121                	addi	sp,sp,64
    80001e9e:	8082                	ret
    return -1;
    80001ea0:	597d                	li	s2,-1
    80001ea2:	b7ed                	j	80001e8c <fork+0x128>

0000000080001ea4 <scheduler>:
{
    80001ea4:	7139                	addi	sp,sp,-64
    80001ea6:	fc06                	sd	ra,56(sp)
    80001ea8:	f822                	sd	s0,48(sp)
    80001eaa:	f426                	sd	s1,40(sp)
    80001eac:	f04a                	sd	s2,32(sp)
    80001eae:	ec4e                	sd	s3,24(sp)
    80001eb0:	e852                	sd	s4,16(sp)
    80001eb2:	e456                	sd	s5,8(sp)
    80001eb4:	e05a                	sd	s6,0(sp)
    80001eb6:	0080                	addi	s0,sp,64
    80001eb8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eba:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ebc:	00779a93          	slli	s5,a5,0x7
    80001ec0:	0000f717          	auipc	a4,0xf
    80001ec4:	3e070713          	addi	a4,a4,992 # 800112a0 <pid_lock>
    80001ec8:	9756                	add	a4,a4,s5
    80001eca:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ece:	0000f717          	auipc	a4,0xf
    80001ed2:	40a70713          	addi	a4,a4,1034 # 800112d8 <cpus+0x8>
    80001ed6:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ed8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eda:	4b11                	li	s6,4
        c->proc = p;
    80001edc:	079e                	slli	a5,a5,0x7
    80001ede:	0000fa17          	auipc	s4,0xf
    80001ee2:	3c2a0a13          	addi	s4,s4,962 # 800112a0 <pid_lock>
    80001ee6:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ee8:	00015917          	auipc	s2,0x15
    80001eec:	1e890913          	addi	s2,s2,488 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef8:	10079073          	csrw	sstatus,a5
    80001efc:	0000f497          	auipc	s1,0xf
    80001f00:	7d448493          	addi	s1,s1,2004 # 800116d0 <proc>
    80001f04:	a811                	j	80001f18 <scheduler+0x74>
      release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d7c080e7          	jalr	-644(ra) # 80000c84 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f10:	16848493          	addi	s1,s1,360
    80001f14:	fd248ee3          	beq	s1,s2,80001ef0 <scheduler+0x4c>
      acquire(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	cb6080e7          	jalr	-842(ra) # 80000bd0 <acquire>
      if (p->state == RUNNABLE)
    80001f22:	4c9c                	lw	a5,24(s1)
    80001f24:	ff3791e3          	bne	a5,s3,80001f06 <scheduler+0x62>
        p->state = RUNNING;
    80001f28:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f30:	06048593          	addi	a1,s1,96
    80001f34:	8556                	mv	a0,s5
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	70a080e7          	jalr	1802(ra) # 80002640 <swtch>
        c->proc = 0;
    80001f3e:	020a3823          	sd	zero,48(s4)
    80001f42:	b7d1                	j	80001f06 <scheduler+0x62>

0000000080001f44 <sched>:
{
    80001f44:	7179                	addi	sp,sp,-48
    80001f46:	f406                	sd	ra,40(sp)
    80001f48:	f022                	sd	s0,32(sp)
    80001f4a:	ec26                	sd	s1,24(sp)
    80001f4c:	e84a                	sd	s2,16(sp)
    80001f4e:	e44e                	sd	s3,8(sp)
    80001f50:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	a44080e7          	jalr	-1468(ra) # 80001996 <myproc>
    80001f5a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	bfa080e7          	jalr	-1030(ra) # 80000b56 <holding>
    80001f64:	c93d                	beqz	a0,80001fda <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f66:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f68:	2781                	sext.w	a5,a5
    80001f6a:	079e                	slli	a5,a5,0x7
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	33470713          	addi	a4,a4,820 # 800112a0 <pid_lock>
    80001f74:	97ba                	add	a5,a5,a4
    80001f76:	0a87a703          	lw	a4,168(a5)
    80001f7a:	4785                	li	a5,1
    80001f7c:	06f71763          	bne	a4,a5,80001fea <sched+0xa6>
  if (p->state == RUNNING)
    80001f80:	4c98                	lw	a4,24(s1)
    80001f82:	4791                	li	a5,4
    80001f84:	06f70b63          	beq	a4,a5,80001ffa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f88:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8c:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f8e:	efb5                	bnez	a5,8000200a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f90:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f92:	0000f917          	auipc	s2,0xf
    80001f96:	30e90913          	addi	s2,s2,782 # 800112a0 <pid_lock>
    80001f9a:	2781                	sext.w	a5,a5
    80001f9c:	079e                	slli	a5,a5,0x7
    80001f9e:	97ca                	add	a5,a5,s2
    80001fa0:	0ac7a983          	lw	s3,172(a5)
    80001fa4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000f597          	auipc	a1,0xf
    80001fae:	32e58593          	addi	a1,a1,814 # 800112d8 <cpus+0x8>
    80001fb2:	95be                	add	a1,a1,a5
    80001fb4:	06048513          	addi	a0,s1,96
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	688080e7          	jalr	1672(ra) # 80002640 <swtch>
    80001fc0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	97ca                	add	a5,a5,s2
    80001fc8:	0b37a623          	sw	s3,172(a5)
}
    80001fcc:	70a2                	ld	ra,40(sp)
    80001fce:	7402                	ld	s0,32(sp)
    80001fd0:	64e2                	ld	s1,24(sp)
    80001fd2:	6942                	ld	s2,16(sp)
    80001fd4:	69a2                	ld	s3,8(sp)
    80001fd6:	6145                	addi	sp,sp,48
    80001fd8:	8082                	ret
    panic("sched p->lock");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	23e50513          	addi	a0,a0,574 # 80008218 <digits+0x1d8>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	556080e7          	jalr	1366(ra) # 80000538 <panic>
    panic("sched locks");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	23e50513          	addi	a0,a0,574 # 80008228 <digits+0x1e8>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	546080e7          	jalr	1350(ra) # 80000538 <panic>
    panic("sched running");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	23e50513          	addi	a0,a0,574 # 80008238 <digits+0x1f8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	536080e7          	jalr	1334(ra) # 80000538 <panic>
    panic("sched interruptible");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	23e50513          	addi	a0,a0,574 # 80008248 <digits+0x208>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	526080e7          	jalr	1318(ra) # 80000538 <panic>

000000008000201a <yield>:
{
    8000201a:	1101                	addi	sp,sp,-32
    8000201c:	ec06                	sd	ra,24(sp)
    8000201e:	e822                	sd	s0,16(sp)
    80002020:	e426                	sd	s1,8(sp)
    80002022:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002024:	00000097          	auipc	ra,0x0
    80002028:	972080e7          	jalr	-1678(ra) # 80001996 <myproc>
    8000202c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	ba2080e7          	jalr	-1118(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002036:	478d                	li	a5,3
    80002038:	cc9c                	sw	a5,24(s1)
  sched();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	f0a080e7          	jalr	-246(ra) # 80001f44 <sched>
  release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c40080e7          	jalr	-960(ra) # 80000c84 <release>
}
    8000204c:	60e2                	ld	ra,24(sp)
    8000204e:	6442                	ld	s0,16(sp)
    80002050:	64a2                	ld	s1,8(sp)
    80002052:	6105                	addi	sp,sp,32
    80002054:	8082                	ret

0000000080002056 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002056:	7179                	addi	sp,sp,-48
    80002058:	f406                	sd	ra,40(sp)
    8000205a:	f022                	sd	s0,32(sp)
    8000205c:	ec26                	sd	s1,24(sp)
    8000205e:	e84a                	sd	s2,16(sp)
    80002060:	e44e                	sd	s3,8(sp)
    80002062:	1800                	addi	s0,sp,48
    80002064:	89aa                	mv	s3,a0
    80002066:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	92e080e7          	jalr	-1746(ra) # 80001996 <myproc>
    80002070:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	b5e080e7          	jalr	-1186(ra) # 80000bd0 <acquire>
  release(lk);
    8000207a:	854a                	mv	a0,s2
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c08080e7          	jalr	-1016(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002084:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002088:	4789                	li	a5,2
    8000208a:	cc9c                	sw	a5,24(s1)

  sched();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	eb8080e7          	jalr	-328(ra) # 80001f44 <sched>

  // Tidy up.
  p->chan = 0;
    80002094:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bea080e7          	jalr	-1046(ra) # 80000c84 <release>
  acquire(lk);
    800020a2:	854a                	mv	a0,s2
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b2c080e7          	jalr	-1236(ra) # 80000bd0 <acquire>
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6145                	addi	sp,sp,48
    800020b8:	8082                	ret

00000000800020ba <wait>:
{
    800020ba:	715d                	addi	sp,sp,-80
    800020bc:	e486                	sd	ra,72(sp)
    800020be:	e0a2                	sd	s0,64(sp)
    800020c0:	fc26                	sd	s1,56(sp)
    800020c2:	f84a                	sd	s2,48(sp)
    800020c4:	f44e                	sd	s3,40(sp)
    800020c6:	f052                	sd	s4,32(sp)
    800020c8:	ec56                	sd	s5,24(sp)
    800020ca:	e85a                	sd	s6,16(sp)
    800020cc:	e45e                	sd	s7,8(sp)
    800020ce:	e062                	sd	s8,0(sp)
    800020d0:	0880                	addi	s0,sp,80
    800020d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	8c2080e7          	jalr	-1854(ra) # 80001996 <myproc>
    800020dc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020de:	0000f517          	auipc	a0,0xf
    800020e2:	1da50513          	addi	a0,a0,474 # 800112b8 <wait_lock>
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	aea080e7          	jalr	-1302(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020ee:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800020f0:	4a15                	li	s4,5
        havekids = 1;
    800020f2:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800020f4:	00015997          	auipc	s3,0x15
    800020f8:	fdc98993          	addi	s3,s3,-36 # 800170d0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800020fc:	0000fc17          	auipc	s8,0xf
    80002100:	1bcc0c13          	addi	s8,s8,444 # 800112b8 <wait_lock>
    havekids = 0;
    80002104:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002106:	0000f497          	auipc	s1,0xf
    8000210a:	5ca48493          	addi	s1,s1,1482 # 800116d0 <proc>
    8000210e:	a0bd                	j	8000217c <wait+0xc2>
          pid = np->pid;
    80002110:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002114:	000b0e63          	beqz	s6,80002130 <wait+0x76>
    80002118:	4691                	li	a3,4
    8000211a:	02c48613          	addi	a2,s1,44
    8000211e:	85da                	mv	a1,s6
    80002120:	05093503          	ld	a0,80(s2)
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	532080e7          	jalr	1330(ra) # 80001656 <copyout>
    8000212c:	02054563          	bltz	a0,80002156 <wait+0x9c>
          freeproc(np);
    80002130:	8526                	mv	a0,s1
    80002132:	00000097          	auipc	ra,0x0
    80002136:	a16080e7          	jalr	-1514(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b48080e7          	jalr	-1208(ra) # 80000c84 <release>
          release(&wait_lock);
    80002144:	0000f517          	auipc	a0,0xf
    80002148:	17450513          	addi	a0,a0,372 # 800112b8 <wait_lock>
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b38080e7          	jalr	-1224(ra) # 80000c84 <release>
          return pid;
    80002154:	a09d                	j	800021ba <wait+0x100>
            release(&np->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b2c080e7          	jalr	-1236(ra) # 80000c84 <release>
            release(&wait_lock);
    80002160:	0000f517          	auipc	a0,0xf
    80002164:	15850513          	addi	a0,a0,344 # 800112b8 <wait_lock>
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>
            return -1;
    80002170:	59fd                	li	s3,-1
    80002172:	a0a1                	j	800021ba <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002174:	16848493          	addi	s1,s1,360
    80002178:	03348463          	beq	s1,s3,800021a0 <wait+0xe6>
      if (np->parent == p)
    8000217c:	7c9c                	ld	a5,56(s1)
    8000217e:	ff279be3          	bne	a5,s2,80002174 <wait+0xba>
        acquire(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a4c080e7          	jalr	-1460(ra) # 80000bd0 <acquire>
        if (np->state == ZOMBIE)
    8000218c:	4c9c                	lw	a5,24(s1)
    8000218e:	f94781e3          	beq	a5,s4,80002110 <wait+0x56>
        release(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	af0080e7          	jalr	-1296(ra) # 80000c84 <release>
        havekids = 1;
    8000219c:	8756                	mv	a4,s5
    8000219e:	bfd9                	j	80002174 <wait+0xba>
    if (!havekids || p->killed)
    800021a0:	c701                	beqz	a4,800021a8 <wait+0xee>
    800021a2:	02892783          	lw	a5,40(s2)
    800021a6:	c79d                	beqz	a5,800021d4 <wait+0x11a>
      release(&wait_lock);
    800021a8:	0000f517          	auipc	a0,0xf
    800021ac:	11050513          	addi	a0,a0,272 # 800112b8 <wait_lock>
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ad4080e7          	jalr	-1324(ra) # 80000c84 <release>
      return -1;
    800021b8:	59fd                	li	s3,-1
}
    800021ba:	854e                	mv	a0,s3
    800021bc:	60a6                	ld	ra,72(sp)
    800021be:	6406                	ld	s0,64(sp)
    800021c0:	74e2                	ld	s1,56(sp)
    800021c2:	7942                	ld	s2,48(sp)
    800021c4:	79a2                	ld	s3,40(sp)
    800021c6:	7a02                	ld	s4,32(sp)
    800021c8:	6ae2                	ld	s5,24(sp)
    800021ca:	6b42                	ld	s6,16(sp)
    800021cc:	6ba2                	ld	s7,8(sp)
    800021ce:	6c02                	ld	s8,0(sp)
    800021d0:	6161                	addi	sp,sp,80
    800021d2:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800021d4:	85e2                	mv	a1,s8
    800021d6:	854a                	mv	a0,s2
    800021d8:	00000097          	auipc	ra,0x0
    800021dc:	e7e080e7          	jalr	-386(ra) # 80002056 <sleep>
    havekids = 0;
    800021e0:	b715                	j	80002104 <wait+0x4a>

00000000800021e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800021e2:	7139                	addi	sp,sp,-64
    800021e4:	fc06                	sd	ra,56(sp)
    800021e6:	f822                	sd	s0,48(sp)
    800021e8:	f426                	sd	s1,40(sp)
    800021ea:	f04a                	sd	s2,32(sp)
    800021ec:	ec4e                	sd	s3,24(sp)
    800021ee:	e852                	sd	s4,16(sp)
    800021f0:	e456                	sd	s5,8(sp)
    800021f2:	0080                	addi	s0,sp,64
    800021f4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800021f6:	0000f497          	auipc	s1,0xf
    800021fa:	4da48493          	addi	s1,s1,1242 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800021fe:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002200:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002202:	00015917          	auipc	s2,0x15
    80002206:	ece90913          	addi	s2,s2,-306 # 800170d0 <tickslock>
    8000220a:	a811                	j	8000221e <wakeup+0x3c>
      }
      release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a76080e7          	jalr	-1418(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002216:	16848493          	addi	s1,s1,360
    8000221a:	03248663          	beq	s1,s2,80002246 <wakeup+0x64>
    if (p != myproc())
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	778080e7          	jalr	1912(ra) # 80001996 <myproc>
    80002226:	fea488e3          	beq	s1,a0,80002216 <wakeup+0x34>
      acquire(&p->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9a4080e7          	jalr	-1628(ra) # 80000bd0 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002234:	4c9c                	lw	a5,24(s1)
    80002236:	fd379be3          	bne	a5,s3,8000220c <wakeup+0x2a>
    8000223a:	709c                	ld	a5,32(s1)
    8000223c:	fd4798e3          	bne	a5,s4,8000220c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002240:	0154ac23          	sw	s5,24(s1)
    80002244:	b7e1                	j	8000220c <wakeup+0x2a>
    }
  }
}
    80002246:	70e2                	ld	ra,56(sp)
    80002248:	7442                	ld	s0,48(sp)
    8000224a:	74a2                	ld	s1,40(sp)
    8000224c:	7902                	ld	s2,32(sp)
    8000224e:	69e2                	ld	s3,24(sp)
    80002250:	6a42                	ld	s4,16(sp)
    80002252:	6aa2                	ld	s5,8(sp)
    80002254:	6121                	addi	sp,sp,64
    80002256:	8082                	ret

0000000080002258 <reparent>:
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	e052                	sd	s4,0(sp)
    80002266:	1800                	addi	s0,sp,48
    80002268:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000226a:	0000f497          	auipc	s1,0xf
    8000226e:	46648493          	addi	s1,s1,1126 # 800116d0 <proc>
      pp->parent = initproc;
    80002272:	00007a17          	auipc	s4,0x7
    80002276:	db6a0a13          	addi	s4,s4,-586 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000227a:	00015997          	auipc	s3,0x15
    8000227e:	e5698993          	addi	s3,s3,-426 # 800170d0 <tickslock>
    80002282:	a029                	j	8000228c <reparent+0x34>
    80002284:	16848493          	addi	s1,s1,360
    80002288:	01348d63          	beq	s1,s3,800022a2 <reparent+0x4a>
    if (pp->parent == p)
    8000228c:	7c9c                	ld	a5,56(s1)
    8000228e:	ff279be3          	bne	a5,s2,80002284 <reparent+0x2c>
      pp->parent = initproc;
    80002292:	000a3503          	ld	a0,0(s4)
    80002296:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	f4a080e7          	jalr	-182(ra) # 800021e2 <wakeup>
    800022a0:	b7d5                	j	80002284 <reparent+0x2c>
}
    800022a2:	70a2                	ld	ra,40(sp)
    800022a4:	7402                	ld	s0,32(sp)
    800022a6:	64e2                	ld	s1,24(sp)
    800022a8:	6942                	ld	s2,16(sp)
    800022aa:	69a2                	ld	s3,8(sp)
    800022ac:	6a02                	ld	s4,0(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret

00000000800022b2 <exit>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	e052                	sd	s4,0(sp)
    800022c0:	1800                	addi	s0,sp,48
    800022c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	6d2080e7          	jalr	1746(ra) # 80001996 <myproc>
    800022cc:	89aa                	mv	s3,a0
  if (p == initproc)
    800022ce:	00007797          	auipc	a5,0x7
    800022d2:	d5a7b783          	ld	a5,-678(a5) # 80009028 <initproc>
    800022d6:	0d050493          	addi	s1,a0,208
    800022da:	15050913          	addi	s2,a0,336
    800022de:	02a79363          	bne	a5,a0,80002304 <exit+0x52>
    panic("init exiting");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	f7e50513          	addi	a0,a0,-130 # 80008260 <digits+0x220>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	24e080e7          	jalr	590(ra) # 80000538 <panic>
      fileclose(f);
    800022f2:	00002097          	auipc	ra,0x2
    800022f6:	268080e7          	jalr	616(ra) # 8000455a <fileclose>
      p->ofile[fd] = 0;
    800022fa:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800022fe:	04a1                	addi	s1,s1,8
    80002300:	01248563          	beq	s1,s2,8000230a <exit+0x58>
    if (p->ofile[fd])
    80002304:	6088                	ld	a0,0(s1)
    80002306:	f575                	bnez	a0,800022f2 <exit+0x40>
    80002308:	bfdd                	j	800022fe <exit+0x4c>
  begin_op();
    8000230a:	00002097          	auipc	ra,0x2
    8000230e:	d84080e7          	jalr	-636(ra) # 8000408e <begin_op>
  iput(p->cwd);
    80002312:	1509b503          	ld	a0,336(s3)
    80002316:	00001097          	auipc	ra,0x1
    8000231a:	560080e7          	jalr	1376(ra) # 80003876 <iput>
  end_op();
    8000231e:	00002097          	auipc	ra,0x2
    80002322:	df0080e7          	jalr	-528(ra) # 8000410e <end_op>
  p->cwd = 0;
    80002326:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232a:	0000f497          	auipc	s1,0xf
    8000232e:	f8e48493          	addi	s1,s1,-114 # 800112b8 <wait_lock>
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	89c080e7          	jalr	-1892(ra) # 80000bd0 <acquire>
  reparent(p);
    8000233c:	854e                	mv	a0,s3
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	f1a080e7          	jalr	-230(ra) # 80002258 <reparent>
  wakeup(p->parent);
    80002346:	0389b503          	ld	a0,56(s3)
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	e98080e7          	jalr	-360(ra) # 800021e2 <wakeup>
  acquire(&p->lock);
    80002352:	854e                	mv	a0,s3
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87c080e7          	jalr	-1924(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000235c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002360:	4795                	li	a5,5
    80002362:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	91c080e7          	jalr	-1764(ra) # 80000c84 <release>
  sched();
    80002370:	00000097          	auipc	ra,0x0
    80002374:	bd4080e7          	jalr	-1068(ra) # 80001f44 <sched>
  panic("zombie exit");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	ef850513          	addi	a0,a0,-264 # 80008270 <digits+0x230>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1b8080e7          	jalr	440(ra) # 80000538 <panic>

0000000080002388 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	33848493          	addi	s1,s1,824 # 800116d0 <proc>
    800023a0:	00015997          	auipc	s3,0x15
    800023a4:	d3098993          	addi	s3,s3,-720 # 800170d0 <tickslock>
  {
    acquire(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	826080e7          	jalr	-2010(ra) # 80000bd0 <acquire>
    if (p->pid == pid)
    800023b2:	589c                	lw	a5,48(s1)
    800023b4:	01278d63          	beq	a5,s2,800023ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8ca080e7          	jalr	-1846(ra) # 80000c84 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023c2:	16848493          	addi	s1,s1,360
    800023c6:	ff3491e3          	bne	s1,s3,800023a8 <kill+0x20>
  }
  return -1;
    800023ca:	557d                	li	a0,-1
    800023cc:	a829                	j	800023e6 <kill+0x5e>
      p->killed = 1;
    800023ce:	4785                	li	a5,1
    800023d0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800023d2:	4c98                	lw	a4,24(s1)
    800023d4:	4789                	li	a5,2
    800023d6:	00f70f63          	beq	a4,a5,800023f4 <kill+0x6c>
      release(&p->lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8a8080e7          	jalr	-1880(ra) # 80000c84 <release>
      return 0;
    800023e4:	4501                	li	a0,0
}
    800023e6:	70a2                	ld	ra,40(sp)
    800023e8:	7402                	ld	s0,32(sp)
    800023ea:	64e2                	ld	s1,24(sp)
    800023ec:	6942                	ld	s2,16(sp)
    800023ee:	69a2                	ld	s3,8(sp)
    800023f0:	6145                	addi	sp,sp,48
    800023f2:	8082                	ret
        p->state = RUNNABLE;
    800023f4:	478d                	li	a5,3
    800023f6:	cc9c                	sw	a5,24(s1)
    800023f8:	b7cd                	j	800023da <kill+0x52>

00000000800023fa <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	84aa                	mv	s1,a0
    8000240c:	892e                	mv	s2,a1
    8000240e:	89b2                	mv	s3,a2
    80002410:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	584080e7          	jalr	1412(ra) # 80001996 <myproc>
  if (user_dst)
    8000241a:	c08d                	beqz	s1,8000243c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000241c:	86d2                	mv	a3,s4
    8000241e:	864e                	mv	a2,s3
    80002420:	85ca                	mv	a1,s2
    80002422:	6928                	ld	a0,80(a0)
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	232080e7          	jalr	562(ra) # 80001656 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000242c:	70a2                	ld	ra,40(sp)
    8000242e:	7402                	ld	s0,32(sp)
    80002430:	64e2                	ld	s1,24(sp)
    80002432:	6942                	ld	s2,16(sp)
    80002434:	69a2                	ld	s3,8(sp)
    80002436:	6a02                	ld	s4,0(sp)
    80002438:	6145                	addi	sp,sp,48
    8000243a:	8082                	ret
    memmove((char *)dst, src, len);
    8000243c:	000a061b          	sext.w	a2,s4
    80002440:	85ce                	mv	a1,s3
    80002442:	854a                	mv	a0,s2
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	8e4080e7          	jalr	-1820(ra) # 80000d28 <memmove>
    return 0;
    8000244c:	8526                	mv	a0,s1
    8000244e:	bff9                	j	8000242c <either_copyout+0x32>

0000000080002450 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	e052                	sd	s4,0(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	892a                	mv	s2,a0
    80002462:	84ae                	mv	s1,a1
    80002464:	89b2                	mv	s3,a2
    80002466:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	52e080e7          	jalr	1326(ra) # 80001996 <myproc>
  if (user_src)
    80002470:	c08d                	beqz	s1,80002492 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002472:	86d2                	mv	a3,s4
    80002474:	864e                	mv	a2,s3
    80002476:	85ca                	mv	a1,s2
    80002478:	6928                	ld	a0,80(a0)
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	268080e7          	jalr	616(ra) # 800016e2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    memmove(dst, (char *)src, len);
    80002492:	000a061b          	sext.w	a2,s4
    80002496:	85ce                	mv	a1,s3
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	88e080e7          	jalr	-1906(ra) # 80000d28 <memmove>
    return 0;
    800024a2:	8526                	mv	a0,s1
    800024a4:	bff9                	j	80002482 <either_copyin+0x32>

00000000800024a6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800024a6:	715d                	addi	sp,sp,-80
    800024a8:	e486                	sd	ra,72(sp)
    800024aa:	e0a2                	sd	s0,64(sp)
    800024ac:	fc26                	sd	s1,56(sp)
    800024ae:	f84a                	sd	s2,48(sp)
    800024b0:	f44e                	sd	s3,40(sp)
    800024b2:	f052                	sd	s4,32(sp)
    800024b4:	ec56                	sd	s5,24(sp)
    800024b6:	e85a                	sd	s6,16(sp)
    800024b8:	e45e                	sd	s7,8(sp)
    800024ba:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800024bc:	00006517          	auipc	a0,0x6
    800024c0:	c0c50513          	addi	a0,a0,-1012 # 800080c8 <digits+0x88>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	0be080e7          	jalr	190(ra) # 80000582 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	35c48493          	addi	s1,s1,860 # 80011828 <proc+0x158>
    800024d4:	00015917          	auipc	s2,0x15
    800024d8:	d5490913          	addi	s2,s2,-684 # 80017228 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024de:	00006997          	auipc	s3,0x6
    800024e2:	da298993          	addi	s3,s3,-606 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024e6:	00006a97          	auipc	s5,0x6
    800024ea:	da2a8a93          	addi	s5,s5,-606 # 80008288 <digits+0x248>
    printf("\n");
    800024ee:	00006a17          	auipc	s4,0x6
    800024f2:	bdaa0a13          	addi	s4,s4,-1062 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f6:	00006b97          	auipc	s7,0x6
    800024fa:	e4ab8b93          	addi	s7,s7,-438 # 80008340 <states.0>
    800024fe:	a00d                	j	80002520 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002500:	ed86a583          	lw	a1,-296(a3)
    80002504:	8556                	mv	a0,s5
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	07c080e7          	jalr	124(ra) # 80000582 <printf>
    printf("\n");
    8000250e:	8552                	mv	a0,s4
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	072080e7          	jalr	114(ra) # 80000582 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002518:	16848493          	addi	s1,s1,360
    8000251c:	03248163          	beq	s1,s2,8000253e <procdump+0x98>
    if (p->state == UNUSED)
    80002520:	86a6                	mv	a3,s1
    80002522:	ec04a783          	lw	a5,-320(s1)
    80002526:	dbed                	beqz	a5,80002518 <procdump+0x72>
      state = "???";
    80002528:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252a:	fcfb6be3          	bltu	s6,a5,80002500 <procdump+0x5a>
    8000252e:	1782                	slli	a5,a5,0x20
    80002530:	9381                	srli	a5,a5,0x20
    80002532:	078e                	slli	a5,a5,0x3
    80002534:	97de                	add	a5,a5,s7
    80002536:	6390                	ld	a2,0(a5)
    80002538:	f661                	bnez	a2,80002500 <procdump+0x5a>
      state = "???";
    8000253a:	864e                	mv	a2,s3
    8000253c:	b7d1                	j	80002500 <procdump+0x5a>
  }
}
    8000253e:	60a6                	ld	ra,72(sp)
    80002540:	6406                	ld	s0,64(sp)
    80002542:	74e2                	ld	s1,56(sp)
    80002544:	7942                	ld	s2,48(sp)
    80002546:	79a2                	ld	s3,40(sp)
    80002548:	7a02                	ld	s4,32(sp)
    8000254a:	6ae2                	ld	s5,24(sp)
    8000254c:	6b42                	ld	s6,16(sp)
    8000254e:	6ba2                	ld	s7,8(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret

0000000080002554 <ps>:

// custom:
void ps(void)
{
    80002554:	711d                	addi	sp,sp,-96
    80002556:	ec86                	sd	ra,88(sp)
    80002558:	e8a2                	sd	s0,80(sp)
    8000255a:	e4a6                	sd	s1,72(sp)
    8000255c:	e0ca                	sd	s2,64(sp)
    8000255e:	fc4e                	sd	s3,56(sp)
    80002560:	f852                	sd	s4,48(sp)
    80002562:	f456                	sd	s5,40(sp)
    80002564:	f05a                	sd	s6,32(sp)
    80002566:	ec5e                	sd	s7,24(sp)
    80002568:	e862                	sd	s8,16(sp)
    8000256a:	e466                	sd	s9,8(sp)
    8000256c:	e06a                	sd	s10,0(sp)
    8000256e:	1080                	addi	s0,sp,96
  struct proc *p;
  char *state;

  printf("pID\tState\tName\tSize\n");
    80002570:	00006517          	auipc	a0,0x6
    80002574:	d6850513          	addi	a0,a0,-664 # 800082d8 <digits+0x298>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	00a080e7          	jalr	10(ra) # 80000582 <printf>

  for (p = proc; p < &proc[NPROC]; p++)
    80002580:	0000f497          	auipc	s1,0xf
    80002584:	2a848493          	addi	s1,s1,680 # 80011828 <proc+0x158>
    80002588:	00015a17          	auipc	s4,0x15
    8000258c:	ca0a0a13          	addi	s4,s4,-864 # 80017228 <bcache+0x140>
    80002590:	4995                	li	s3,5
  {
    state = "OTHER";
    80002592:	00006d17          	auipc	s10,0x6
    80002596:	d0ed0d13          	addi	s10,s10,-754 # 800082a0 <digits+0x260>
    8000259a:	00006917          	auipc	s2,0x6
    8000259e:	d8e90913          	addi	s2,s2,-626 # 80008328 <digits+0x2e8>
      break;
    case UNUSED:
      state = "UNUSED";
      continue;
    case USED:
      state = "USED";
    800025a2:	00006c97          	auipc	s9,0x6
    800025a6:	cf6c8c93          	addi	s9,s9,-778 # 80008298 <digits+0x258>
      state = "ZOMBIE";
    800025aa:	00006c17          	auipc	s8,0x6
    800025ae:	d16c0c13          	addi	s8,s8,-746 # 800082c0 <digits+0x280>
      state = "RUNNING";
    800025b2:	00006b97          	auipc	s7,0x6
    800025b6:	d06b8b93          	addi	s7,s7,-762 # 800082b8 <digits+0x278>
      state = "RUNNABLE";
    800025ba:	00006b17          	auipc	s6,0x6
    800025be:	ceeb0b13          	addi	s6,s6,-786 # 800082a8 <digits+0x268>
    switch (p->state)
    800025c2:	00006a97          	auipc	s5,0x6
    800025c6:	d06a8a93          	addi	s5,s5,-762 # 800082c8 <digits+0x288>
    800025ca:	a03d                	j	800025f8 <ps+0xa4>
    800025cc:	86d6                	mv	a3,s5
      break;
    }
    printf("%d.%d\t%s\t%s\t%d\n", p->parent ? p->parent->pid : 0, p->pid, state, p->name, p->sz);
    800025ce:	ee073783          	ld	a5,-288(a4)
    800025d2:	4581                	li	a1,0
    800025d4:	c391                	beqz	a5,800025d8 <ps+0x84>
    800025d6:	5b8c                	lw	a1,48(a5)
    800025d8:	ef073783          	ld	a5,-272(a4)
    800025dc:	ed872603          	lw	a2,-296(a4)
    800025e0:	00006517          	auipc	a0,0x6
    800025e4:	d1050513          	addi	a0,a0,-752 # 800082f0 <digits+0x2b0>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	f9a080e7          	jalr	-102(ra) # 80000582 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025f0:	16848493          	addi	s1,s1,360
    800025f4:	03448863          	beq	s1,s4,80002624 <ps+0xd0>
    switch (p->state)
    800025f8:	8726                	mv	a4,s1
    800025fa:	ec04a783          	lw	a5,-320(s1)
    800025fe:	02f9e163          	bltu	s3,a5,80002620 <ps+0xcc>
    80002602:	ec04e783          	lwu	a5,-320(s1)
    80002606:	078a                	slli	a5,a5,0x2
    80002608:	97ca                	add	a5,a5,s2
    8000260a:	439c                	lw	a5,0(a5)
    8000260c:	97ca                	add	a5,a5,s2
    8000260e:	8782                	jr	a5
      state = "RUNNABLE";
    80002610:	86da                	mv	a3,s6
      break;
    80002612:	bf75                	j	800025ce <ps+0x7a>
      state = "RUNNING";
    80002614:	86de                	mv	a3,s7
      break;
    80002616:	bf65                	j	800025ce <ps+0x7a>
      state = "ZOMBIE";
    80002618:	86e2                	mv	a3,s8
      break;
    8000261a:	bf55                	j	800025ce <ps+0x7a>
      state = "USED";
    8000261c:	86e6                	mv	a3,s9
      break;
    8000261e:	bf45                	j	800025ce <ps+0x7a>
    state = "OTHER";
    80002620:	86ea                	mv	a3,s10
    80002622:	b775                	j	800025ce <ps+0x7a>
  }
}
    80002624:	60e6                	ld	ra,88(sp)
    80002626:	6446                	ld	s0,80(sp)
    80002628:	64a6                	ld	s1,72(sp)
    8000262a:	6906                	ld	s2,64(sp)
    8000262c:	79e2                	ld	s3,56(sp)
    8000262e:	7a42                	ld	s4,48(sp)
    80002630:	7aa2                	ld	s5,40(sp)
    80002632:	7b02                	ld	s6,32(sp)
    80002634:	6be2                	ld	s7,24(sp)
    80002636:	6c42                	ld	s8,16(sp)
    80002638:	6ca2                	ld	s9,8(sp)
    8000263a:	6d02                	ld	s10,0(sp)
    8000263c:	6125                	addi	sp,sp,96
    8000263e:	8082                	ret

0000000080002640 <swtch>:
    80002640:	00153023          	sd	ra,0(a0)
    80002644:	00253423          	sd	sp,8(a0)
    80002648:	e900                	sd	s0,16(a0)
    8000264a:	ed04                	sd	s1,24(a0)
    8000264c:	03253023          	sd	s2,32(a0)
    80002650:	03353423          	sd	s3,40(a0)
    80002654:	03453823          	sd	s4,48(a0)
    80002658:	03553c23          	sd	s5,56(a0)
    8000265c:	05653023          	sd	s6,64(a0)
    80002660:	05753423          	sd	s7,72(a0)
    80002664:	05853823          	sd	s8,80(a0)
    80002668:	05953c23          	sd	s9,88(a0)
    8000266c:	07a53023          	sd	s10,96(a0)
    80002670:	07b53423          	sd	s11,104(a0)
    80002674:	0005b083          	ld	ra,0(a1)
    80002678:	0085b103          	ld	sp,8(a1)
    8000267c:	6980                	ld	s0,16(a1)
    8000267e:	6d84                	ld	s1,24(a1)
    80002680:	0205b903          	ld	s2,32(a1)
    80002684:	0285b983          	ld	s3,40(a1)
    80002688:	0305ba03          	ld	s4,48(a1)
    8000268c:	0385ba83          	ld	s5,56(a1)
    80002690:	0405bb03          	ld	s6,64(a1)
    80002694:	0485bb83          	ld	s7,72(a1)
    80002698:	0505bc03          	ld	s8,80(a1)
    8000269c:	0585bc83          	ld	s9,88(a1)
    800026a0:	0605bd03          	ld	s10,96(a1)
    800026a4:	0685bd83          	ld	s11,104(a1)
    800026a8:	8082                	ret

00000000800026aa <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026aa:	1141                	addi	sp,sp,-16
    800026ac:	e406                	sd	ra,8(sp)
    800026ae:	e022                	sd	s0,0(sp)
    800026b0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026b2:	00006597          	auipc	a1,0x6
    800026b6:	cbe58593          	addi	a1,a1,-834 # 80008370 <states.0+0x30>
    800026ba:	00015517          	auipc	a0,0x15
    800026be:	a1650513          	addi	a0,a0,-1514 # 800170d0 <tickslock>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	47e080e7          	jalr	1150(ra) # 80000b40 <initlock>
}
    800026ca:	60a2                	ld	ra,8(sp)
    800026cc:	6402                	ld	s0,0(sp)
    800026ce:	0141                	addi	sp,sp,16
    800026d0:	8082                	ret

00000000800026d2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026d2:	1141                	addi	sp,sp,-16
    800026d4:	e422                	sd	s0,8(sp)
    800026d6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d8:	00003797          	auipc	a5,0x3
    800026dc:	4a878793          	addi	a5,a5,1192 # 80005b80 <kernelvec>
    800026e0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026e4:	6422                	ld	s0,8(sp)
    800026e6:	0141                	addi	sp,sp,16
    800026e8:	8082                	ret

00000000800026ea <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ea:	1141                	addi	sp,sp,-16
    800026ec:	e406                	sd	ra,8(sp)
    800026ee:	e022                	sd	s0,0(sp)
    800026f0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	2a4080e7          	jalr	676(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002700:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002704:	00005617          	auipc	a2,0x5
    80002708:	8fc60613          	addi	a2,a2,-1796 # 80007000 <_trampoline>
    8000270c:	00005697          	auipc	a3,0x5
    80002710:	8f468693          	addi	a3,a3,-1804 # 80007000 <_trampoline>
    80002714:	8e91                	sub	a3,a3,a2
    80002716:	040007b7          	lui	a5,0x4000
    8000271a:	17fd                	addi	a5,a5,-1
    8000271c:	07b2                	slli	a5,a5,0xc
    8000271e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002724:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002726:	180026f3          	csrr	a3,satp
    8000272a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000272c:	6d38                	ld	a4,88(a0)
    8000272e:	6134                	ld	a3,64(a0)
    80002730:	6585                	lui	a1,0x1
    80002732:	96ae                	add	a3,a3,a1
    80002734:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002736:	6d38                	ld	a4,88(a0)
    80002738:	00000697          	auipc	a3,0x0
    8000273c:	13868693          	addi	a3,a3,312 # 80002870 <usertrap>
    80002740:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002744:	8692                	mv	a3,tp
    80002746:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002748:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000274c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002750:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002754:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002758:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000275a:	6f18                	ld	a4,24(a4)
    8000275c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002760:	692c                	ld	a1,80(a0)
    80002762:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002764:	00005717          	auipc	a4,0x5
    80002768:	92c70713          	addi	a4,a4,-1748 # 80007090 <userret>
    8000276c:	8f11                	sub	a4,a4,a2
    8000276e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002770:	577d                	li	a4,-1
    80002772:	177e                	slli	a4,a4,0x3f
    80002774:	8dd9                	or	a1,a1,a4
    80002776:	02000537          	lui	a0,0x2000
    8000277a:	157d                	addi	a0,a0,-1
    8000277c:	0536                	slli	a0,a0,0xd
    8000277e:	9782                	jalr	a5
}
    80002780:	60a2                	ld	ra,8(sp)
    80002782:	6402                	ld	s0,0(sp)
    80002784:	0141                	addi	sp,sp,16
    80002786:	8082                	ret

0000000080002788 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002788:	1101                	addi	sp,sp,-32
    8000278a:	ec06                	sd	ra,24(sp)
    8000278c:	e822                	sd	s0,16(sp)
    8000278e:	e426                	sd	s1,8(sp)
    80002790:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002792:	00015497          	auipc	s1,0x15
    80002796:	93e48493          	addi	s1,s1,-1730 # 800170d0 <tickslock>
    8000279a:	8526                	mv	a0,s1
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	434080e7          	jalr	1076(ra) # 80000bd0 <acquire>
  ticks++;
    800027a4:	00007517          	auipc	a0,0x7
    800027a8:	88c50513          	addi	a0,a0,-1908 # 80009030 <ticks>
    800027ac:	411c                	lw	a5,0(a0)
    800027ae:	2785                	addiw	a5,a5,1
    800027b0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027b2:	00000097          	auipc	ra,0x0
    800027b6:	a30080e7          	jalr	-1488(ra) # 800021e2 <wakeup>
  release(&tickslock);
    800027ba:	8526                	mv	a0,s1
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4c8080e7          	jalr	1224(ra) # 80000c84 <release>
}
    800027c4:	60e2                	ld	ra,24(sp)
    800027c6:	6442                	ld	s0,16(sp)
    800027c8:	64a2                	ld	s1,8(sp)
    800027ca:	6105                	addi	sp,sp,32
    800027cc:	8082                	ret

00000000800027ce <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ce:	1101                	addi	sp,sp,-32
    800027d0:	ec06                	sd	ra,24(sp)
    800027d2:	e822                	sd	s0,16(sp)
    800027d4:	e426                	sd	s1,8(sp)
    800027d6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027d8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027dc:	00074d63          	bltz	a4,800027f6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027e0:	57fd                	li	a5,-1
    800027e2:	17fe                	slli	a5,a5,0x3f
    800027e4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027e8:	06f70363          	beq	a4,a5,8000284e <devintr+0x80>
  }
}
    800027ec:	60e2                	ld	ra,24(sp)
    800027ee:	6442                	ld	s0,16(sp)
    800027f0:	64a2                	ld	s1,8(sp)
    800027f2:	6105                	addi	sp,sp,32
    800027f4:	8082                	ret
     (scause & 0xff) == 9){
    800027f6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027fa:	46a5                	li	a3,9
    800027fc:	fed792e3          	bne	a5,a3,800027e0 <devintr+0x12>
    int irq = plic_claim();
    80002800:	00003097          	auipc	ra,0x3
    80002804:	488080e7          	jalr	1160(ra) # 80005c88 <plic_claim>
    80002808:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000280a:	47a9                	li	a5,10
    8000280c:	02f50763          	beq	a0,a5,8000283a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002810:	4785                	li	a5,1
    80002812:	02f50963          	beq	a0,a5,80002844 <devintr+0x76>
    return 1;
    80002816:	4505                	li	a0,1
    } else if(irq){
    80002818:	d8f1                	beqz	s1,800027ec <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000281a:	85a6                	mv	a1,s1
    8000281c:	00006517          	auipc	a0,0x6
    80002820:	b5c50513          	addi	a0,a0,-1188 # 80008378 <states.0+0x38>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	d5e080e7          	jalr	-674(ra) # 80000582 <printf>
      plic_complete(irq);
    8000282c:	8526                	mv	a0,s1
    8000282e:	00003097          	auipc	ra,0x3
    80002832:	47e080e7          	jalr	1150(ra) # 80005cac <plic_complete>
    return 1;
    80002836:	4505                	li	a0,1
    80002838:	bf55                	j	800027ec <devintr+0x1e>
      uartintr();
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	15a080e7          	jalr	346(ra) # 80000994 <uartintr>
    80002842:	b7ed                	j	8000282c <devintr+0x5e>
      virtio_disk_intr();
    80002844:	00004097          	auipc	ra,0x4
    80002848:	8fa080e7          	jalr	-1798(ra) # 8000613e <virtio_disk_intr>
    8000284c:	b7c5                	j	8000282c <devintr+0x5e>
    if(cpuid() == 0){
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	11c080e7          	jalr	284(ra) # 8000196a <cpuid>
    80002856:	c901                	beqz	a0,80002866 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002858:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000285c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000285e:	14479073          	csrw	sip,a5
    return 2;
    80002862:	4509                	li	a0,2
    80002864:	b761                	j	800027ec <devintr+0x1e>
      clockintr();
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	f22080e7          	jalr	-222(ra) # 80002788 <clockintr>
    8000286e:	b7ed                	j	80002858 <devintr+0x8a>

0000000080002870 <usertrap>:
{
    80002870:	1101                	addi	sp,sp,-32
    80002872:	ec06                	sd	ra,24(sp)
    80002874:	e822                	sd	s0,16(sp)
    80002876:	e426                	sd	s1,8(sp)
    80002878:	e04a                	sd	s2,0(sp)
    8000287a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002880:	1007f793          	andi	a5,a5,256
    80002884:	e3ad                	bnez	a5,800028e6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002886:	00003797          	auipc	a5,0x3
    8000288a:	2fa78793          	addi	a5,a5,762 # 80005b80 <kernelvec>
    8000288e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	104080e7          	jalr	260(ra) # 80001996 <myproc>
    8000289a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000289c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000289e:	14102773          	csrr	a4,sepc
    800028a2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028a8:	47a1                	li	a5,8
    800028aa:	04f71c63          	bne	a4,a5,80002902 <usertrap+0x92>
    if(p->killed)
    800028ae:	551c                	lw	a5,40(a0)
    800028b0:	e3b9                	bnez	a5,800028f6 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028b2:	6cb8                	ld	a4,88(s1)
    800028b4:	6f1c                	ld	a5,24(a4)
    800028b6:	0791                	addi	a5,a5,4
    800028b8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028be:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c2:	10079073          	csrw	sstatus,a5
    syscall();
    800028c6:	00000097          	auipc	ra,0x0
    800028ca:	2e0080e7          	jalr	736(ra) # 80002ba6 <syscall>
  if(p->killed)
    800028ce:	549c                	lw	a5,40(s1)
    800028d0:	ebc1                	bnez	a5,80002960 <usertrap+0xf0>
  usertrapret();
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	e18080e7          	jalr	-488(ra) # 800026ea <usertrapret>
}
    800028da:	60e2                	ld	ra,24(sp)
    800028dc:	6442                	ld	s0,16(sp)
    800028de:	64a2                	ld	s1,8(sp)
    800028e0:	6902                	ld	s2,0(sp)
    800028e2:	6105                	addi	sp,sp,32
    800028e4:	8082                	ret
    panic("usertrap: not from user mode");
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	ab250513          	addi	a0,a0,-1358 # 80008398 <states.0+0x58>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	c4a080e7          	jalr	-950(ra) # 80000538 <panic>
      exit(-1);
    800028f6:	557d                	li	a0,-1
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	9ba080e7          	jalr	-1606(ra) # 800022b2 <exit>
    80002900:	bf4d                	j	800028b2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002902:	00000097          	auipc	ra,0x0
    80002906:	ecc080e7          	jalr	-308(ra) # 800027ce <devintr>
    8000290a:	892a                	mv	s2,a0
    8000290c:	c501                	beqz	a0,80002914 <usertrap+0xa4>
  if(p->killed)
    8000290e:	549c                	lw	a5,40(s1)
    80002910:	c3a1                	beqz	a5,80002950 <usertrap+0xe0>
    80002912:	a815                	j	80002946 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002914:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002918:	5890                	lw	a2,48(s1)
    8000291a:	00006517          	auipc	a0,0x6
    8000291e:	a9e50513          	addi	a0,a0,-1378 # 800083b8 <states.0+0x78>
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	c60080e7          	jalr	-928(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000292e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002932:	00006517          	auipc	a0,0x6
    80002936:	ab650513          	addi	a0,a0,-1354 # 800083e8 <states.0+0xa8>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	c48080e7          	jalr	-952(ra) # 80000582 <printf>
    p->killed = 1;
    80002942:	4785                	li	a5,1
    80002944:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002946:	557d                	li	a0,-1
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	96a080e7          	jalr	-1686(ra) # 800022b2 <exit>
  if(which_dev == 2)
    80002950:	4789                	li	a5,2
    80002952:	f8f910e3          	bne	s2,a5,800028d2 <usertrap+0x62>
    yield();
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	6c4080e7          	jalr	1732(ra) # 8000201a <yield>
    8000295e:	bf95                	j	800028d2 <usertrap+0x62>
  int which_dev = 0;
    80002960:	4901                	li	s2,0
    80002962:	b7d5                	j	80002946 <usertrap+0xd6>

0000000080002964 <kerneltrap>:
{
    80002964:	7179                	addi	sp,sp,-48
    80002966:	f406                	sd	ra,40(sp)
    80002968:	f022                	sd	s0,32(sp)
    8000296a:	ec26                	sd	s1,24(sp)
    8000296c:	e84a                	sd	s2,16(sp)
    8000296e:	e44e                	sd	s3,8(sp)
    80002970:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002972:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002976:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000297e:	1004f793          	andi	a5,s1,256
    80002982:	cb85                	beqz	a5,800029b2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002984:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002988:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000298a:	ef85                	bnez	a5,800029c2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	e42080e7          	jalr	-446(ra) # 800027ce <devintr>
    80002994:	cd1d                	beqz	a0,800029d2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002996:	4789                	li	a5,2
    80002998:	06f50a63          	beq	a0,a5,80002a0c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000299c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a0:	10049073          	csrw	sstatus,s1
}
    800029a4:	70a2                	ld	ra,40(sp)
    800029a6:	7402                	ld	s0,32(sp)
    800029a8:	64e2                	ld	s1,24(sp)
    800029aa:	6942                	ld	s2,16(sp)
    800029ac:	69a2                	ld	s3,8(sp)
    800029ae:	6145                	addi	sp,sp,48
    800029b0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a5650513          	addi	a0,a0,-1450 # 80008408 <states.0+0xc8>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b7e080e7          	jalr	-1154(ra) # 80000538 <panic>
    panic("kerneltrap: interrupts enabled");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	a6e50513          	addi	a0,a0,-1426 # 80008430 <states.0+0xf0>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	b6e080e7          	jalr	-1170(ra) # 80000538 <panic>
    printf("scause %p\n", scause);
    800029d2:	85ce                	mv	a1,s3
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	a7c50513          	addi	a0,a0,-1412 # 80008450 <states.0+0x110>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	ba6080e7          	jalr	-1114(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	a7450513          	addi	a0,a0,-1420 # 80008460 <states.0+0x120>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b8e080e7          	jalr	-1138(ra) # 80000582 <printf>
    panic("kerneltrap");
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	a7c50513          	addi	a0,a0,-1412 # 80008478 <states.0+0x138>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b34080e7          	jalr	-1228(ra) # 80000538 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	f8a080e7          	jalr	-118(ra) # 80001996 <myproc>
    80002a14:	d541                	beqz	a0,8000299c <kerneltrap+0x38>
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	f80080e7          	jalr	-128(ra) # 80001996 <myproc>
    80002a1e:	4d18                	lw	a4,24(a0)
    80002a20:	4791                	li	a5,4
    80002a22:	f6f71de3          	bne	a4,a5,8000299c <kerneltrap+0x38>
    yield();
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	5f4080e7          	jalr	1524(ra) # 8000201a <yield>
    80002a2e:	b7bd                	j	8000299c <kerneltrap+0x38>

0000000080002a30 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a30:	1101                	addi	sp,sp,-32
    80002a32:	ec06                	sd	ra,24(sp)
    80002a34:	e822                	sd	s0,16(sp)
    80002a36:	e426                	sd	s1,8(sp)
    80002a38:	1000                	addi	s0,sp,32
    80002a3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	f5a080e7          	jalr	-166(ra) # 80001996 <myproc>
  switch (n)
    80002a44:	4795                	li	a5,5
    80002a46:	0497e163          	bltu	a5,s1,80002a88 <argraw+0x58>
    80002a4a:	048a                	slli	s1,s1,0x2
    80002a4c:	00006717          	auipc	a4,0x6
    80002a50:	a6470713          	addi	a4,a4,-1436 # 800084b0 <states.0+0x170>
    80002a54:	94ba                	add	s1,s1,a4
    80002a56:	409c                	lw	a5,0(s1)
    80002a58:	97ba                	add	a5,a5,a4
    80002a5a:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002a5c:	6d3c                	ld	a5,88(a0)
    80002a5e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a60:	60e2                	ld	ra,24(sp)
    80002a62:	6442                	ld	s0,16(sp)
    80002a64:	64a2                	ld	s1,8(sp)
    80002a66:	6105                	addi	sp,sp,32
    80002a68:	8082                	ret
    return p->trapframe->a1;
    80002a6a:	6d3c                	ld	a5,88(a0)
    80002a6c:	7fa8                	ld	a0,120(a5)
    80002a6e:	bfcd                	j	80002a60 <argraw+0x30>
    return p->trapframe->a2;
    80002a70:	6d3c                	ld	a5,88(a0)
    80002a72:	63c8                	ld	a0,128(a5)
    80002a74:	b7f5                	j	80002a60 <argraw+0x30>
    return p->trapframe->a3;
    80002a76:	6d3c                	ld	a5,88(a0)
    80002a78:	67c8                	ld	a0,136(a5)
    80002a7a:	b7dd                	j	80002a60 <argraw+0x30>
    return p->trapframe->a4;
    80002a7c:	6d3c                	ld	a5,88(a0)
    80002a7e:	6bc8                	ld	a0,144(a5)
    80002a80:	b7c5                	j	80002a60 <argraw+0x30>
    return p->trapframe->a5;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	6fc8                	ld	a0,152(a5)
    80002a86:	bfe9                	j	80002a60 <argraw+0x30>
  panic("argraw");
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	a0050513          	addi	a0,a0,-1536 # 80008488 <states.0+0x148>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	aa8080e7          	jalr	-1368(ra) # 80000538 <panic>

0000000080002a98 <fetchaddr>:
{
    80002a98:	1101                	addi	sp,sp,-32
    80002a9a:	ec06                	sd	ra,24(sp)
    80002a9c:	e822                	sd	s0,16(sp)
    80002a9e:	e426                	sd	s1,8(sp)
    80002aa0:	e04a                	sd	s2,0(sp)
    80002aa2:	1000                	addi	s0,sp,32
    80002aa4:	84aa                	mv	s1,a0
    80002aa6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	eee080e7          	jalr	-274(ra) # 80001996 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002ab0:	653c                	ld	a5,72(a0)
    80002ab2:	02f4f863          	bgeu	s1,a5,80002ae2 <fetchaddr+0x4a>
    80002ab6:	00848713          	addi	a4,s1,8
    80002aba:	02e7e663          	bltu	a5,a4,80002ae6 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002abe:	46a1                	li	a3,8
    80002ac0:	8626                	mv	a2,s1
    80002ac2:	85ca                	mv	a1,s2
    80002ac4:	6928                	ld	a0,80(a0)
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	c1c080e7          	jalr	-996(ra) # 800016e2 <copyin>
    80002ace:	00a03533          	snez	a0,a0
    80002ad2:	40a00533          	neg	a0,a0
}
    80002ad6:	60e2                	ld	ra,24(sp)
    80002ad8:	6442                	ld	s0,16(sp)
    80002ada:	64a2                	ld	s1,8(sp)
    80002adc:	6902                	ld	s2,0(sp)
    80002ade:	6105                	addi	sp,sp,32
    80002ae0:	8082                	ret
    return -1;
    80002ae2:	557d                	li	a0,-1
    80002ae4:	bfcd                	j	80002ad6 <fetchaddr+0x3e>
    80002ae6:	557d                	li	a0,-1
    80002ae8:	b7fd                	j	80002ad6 <fetchaddr+0x3e>

0000000080002aea <fetchstr>:
{
    80002aea:	7179                	addi	sp,sp,-48
    80002aec:	f406                	sd	ra,40(sp)
    80002aee:	f022                	sd	s0,32(sp)
    80002af0:	ec26                	sd	s1,24(sp)
    80002af2:	e84a                	sd	s2,16(sp)
    80002af4:	e44e                	sd	s3,8(sp)
    80002af6:	1800                	addi	s0,sp,48
    80002af8:	892a                	mv	s2,a0
    80002afa:	84ae                	mv	s1,a1
    80002afc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	e98080e7          	jalr	-360(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b06:	86ce                	mv	a3,s3
    80002b08:	864a                	mv	a2,s2
    80002b0a:	85a6                	mv	a1,s1
    80002b0c:	6928                	ld	a0,80(a0)
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	c62080e7          	jalr	-926(ra) # 80001770 <copyinstr>
  if (err < 0)
    80002b16:	00054763          	bltz	a0,80002b24 <fetchstr+0x3a>
  return strlen(buf);
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	32c080e7          	jalr	812(ra) # 80000e48 <strlen>
}
    80002b24:	70a2                	ld	ra,40(sp)
    80002b26:	7402                	ld	s0,32(sp)
    80002b28:	64e2                	ld	s1,24(sp)
    80002b2a:	6942                	ld	s2,16(sp)
    80002b2c:	69a2                	ld	s3,8(sp)
    80002b2e:	6145                	addi	sp,sp,48
    80002b30:	8082                	ret

0000000080002b32 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	1000                	addi	s0,sp,32
    80002b3c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b3e:	00000097          	auipc	ra,0x0
    80002b42:	ef2080e7          	jalr	-270(ra) # 80002a30 <argraw>
    80002b46:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b48:	4501                	li	a0,0
    80002b4a:	60e2                	ld	ra,24(sp)
    80002b4c:	6442                	ld	s0,16(sp)
    80002b4e:	64a2                	ld	s1,8(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret

0000000080002b54 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002b54:	1101                	addi	sp,sp,-32
    80002b56:	ec06                	sd	ra,24(sp)
    80002b58:	e822                	sd	s0,16(sp)
    80002b5a:	e426                	sd	s1,8(sp)
    80002b5c:	1000                	addi	s0,sp,32
    80002b5e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	ed0080e7          	jalr	-304(ra) # 80002a30 <argraw>
    80002b68:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b6a:	4501                	li	a0,0
    80002b6c:	60e2                	ld	ra,24(sp)
    80002b6e:	6442                	ld	s0,16(sp)
    80002b70:	64a2                	ld	s1,8(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret

0000000080002b76 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	e04a                	sd	s2,0(sp)
    80002b80:	1000                	addi	s0,sp,32
    80002b82:	84ae                	mv	s1,a1
    80002b84:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	eaa080e7          	jalr	-342(ra) # 80002a30 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b8e:	864a                	mv	a2,s2
    80002b90:	85a6                	mv	a1,s1
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	f58080e7          	jalr	-168(ra) # 80002aea <fetchstr>
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6902                	ld	s2,0(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <syscall>:
    // custom:
    [SYS_ps] sys_ps,
};

void syscall(void)
{
    80002ba6:	1101                	addi	sp,sp,-32
    80002ba8:	ec06                	sd	ra,24(sp)
    80002baa:	e822                	sd	s0,16(sp)
    80002bac:	e426                	sd	s1,8(sp)
    80002bae:	e04a                	sd	s2,0(sp)
    80002bb0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	de4080e7          	jalr	-540(ra) # 80001996 <myproc>
    80002bba:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bbc:	05853903          	ld	s2,88(a0)
    80002bc0:	0a893783          	ld	a5,168(s2)
    80002bc4:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002bc8:	37fd                	addiw	a5,a5,-1
    80002bca:	4755                	li	a4,21
    80002bcc:	00f76f63          	bltu	a4,a5,80002bea <syscall+0x44>
    80002bd0:	00369713          	slli	a4,a3,0x3
    80002bd4:	00006797          	auipc	a5,0x6
    80002bd8:	8f478793          	addi	a5,a5,-1804 # 800084c8 <syscalls>
    80002bdc:	97ba                	add	a5,a5,a4
    80002bde:	639c                	ld	a5,0(a5)
    80002be0:	c789                	beqz	a5,80002bea <syscall+0x44>
  {
    p->trapframe->a0 = syscalls[num]();
    80002be2:	9782                	jalr	a5
    80002be4:	06a93823          	sd	a0,112(s2)
    80002be8:	a839                	j	80002c06 <syscall+0x60>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002bea:	15848613          	addi	a2,s1,344
    80002bee:	588c                	lw	a1,48(s1)
    80002bf0:	00006517          	auipc	a0,0x6
    80002bf4:	8a050513          	addi	a0,a0,-1888 # 80008490 <states.0+0x150>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	98a080e7          	jalr	-1654(ra) # 80000582 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c00:	6cbc                	ld	a5,88(s1)
    80002c02:	577d                	li	a4,-1
    80002c04:	fbb8                	sd	a4,112(a5)
  }
}
    80002c06:	60e2                	ld	ra,24(sp)
    80002c08:	6442                	ld	s0,16(sp)
    80002c0a:	64a2                	ld	s1,8(sp)
    80002c0c:	6902                	ld	s2,0(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret

0000000080002c12 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002c1a:	fec40593          	addi	a1,s0,-20
    80002c1e:	4501                	li	a0,0
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	f12080e7          	jalr	-238(ra) # 80002b32 <argint>
    return -1;
    80002c28:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002c2a:	00054963          	bltz	a0,80002c3c <sys_exit+0x2a>
  exit(n);
    80002c2e:	fec42503          	lw	a0,-20(s0)
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	680080e7          	jalr	1664(ra) # 800022b2 <exit>
  return 0; // not reached
    80002c3a:	4781                	li	a5,0
}
    80002c3c:	853e                	mv	a0,a5
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret

0000000080002c46 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c46:	1141                	addi	sp,sp,-16
    80002c48:	e406                	sd	ra,8(sp)
    80002c4a:	e022                	sd	s0,0(sp)
    80002c4c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	d48080e7          	jalr	-696(ra) # 80001996 <myproc>
}
    80002c56:	5908                	lw	a0,48(a0)
    80002c58:	60a2                	ld	ra,8(sp)
    80002c5a:	6402                	ld	s0,0(sp)
    80002c5c:	0141                	addi	sp,sp,16
    80002c5e:	8082                	ret

0000000080002c60 <sys_fork>:

uint64
sys_fork(void)
{
    80002c60:	1141                	addi	sp,sp,-16
    80002c62:	e406                	sd	ra,8(sp)
    80002c64:	e022                	sd	s0,0(sp)
    80002c66:	0800                	addi	s0,sp,16
  return fork();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	0fc080e7          	jalr	252(ra) # 80001d64 <fork>
}
    80002c70:	60a2                	ld	ra,8(sp)
    80002c72:	6402                	ld	s0,0(sp)
    80002c74:	0141                	addi	sp,sp,16
    80002c76:	8082                	ret

0000000080002c78 <sys_wait>:

uint64
sys_wait(void)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002c80:	fe840593          	addi	a1,s0,-24
    80002c84:	4501                	li	a0,0
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	ece080e7          	jalr	-306(ra) # 80002b54 <argaddr>
    80002c8e:	87aa                	mv	a5,a0
    return -1;
    80002c90:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002c92:	0007c863          	bltz	a5,80002ca2 <sys_wait+0x2a>
  return wait(p);
    80002c96:	fe843503          	ld	a0,-24(s0)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	420080e7          	jalr	1056(ra) # 800020ba <wait>
}
    80002ca2:	60e2                	ld	ra,24(sp)
    80002ca4:	6442                	ld	s0,16(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002cb4:	fdc40593          	addi	a1,s0,-36
    80002cb8:	4501                	li	a0,0
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	e78080e7          	jalr	-392(ra) # 80002b32 <argint>
    return -1;
    80002cc2:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    80002cc4:	00054f63          	bltz	a0,80002ce2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	cce080e7          	jalr	-818(ra) # 80001996 <myproc>
    80002cd0:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    80002cd2:	fdc42503          	lw	a0,-36(s0)
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	01a080e7          	jalr	26(ra) # 80001cf0 <growproc>
    80002cde:	00054863          	bltz	a0,80002cee <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002ce2:	8526                	mv	a0,s1
    80002ce4:	70a2                	ld	ra,40(sp)
    80002ce6:	7402                	ld	s0,32(sp)
    80002ce8:	64e2                	ld	s1,24(sp)
    80002cea:	6145                	addi	sp,sp,48
    80002cec:	8082                	ret
    return -1;
    80002cee:	54fd                	li	s1,-1
    80002cf0:	bfcd                	j	80002ce2 <sys_sbrk+0x38>

0000000080002cf2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cf2:	7139                	addi	sp,sp,-64
    80002cf4:	fc06                	sd	ra,56(sp)
    80002cf6:	f822                	sd	s0,48(sp)
    80002cf8:	f426                	sd	s1,40(sp)
    80002cfa:	f04a                	sd	s2,32(sp)
    80002cfc:	ec4e                	sd	s3,24(sp)
    80002cfe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002d00:	fcc40593          	addi	a1,s0,-52
    80002d04:	4501                	li	a0,0
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	e2c080e7          	jalr	-468(ra) # 80002b32 <argint>
    return -1;
    80002d0e:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002d10:	06054563          	bltz	a0,80002d7a <sys_sleep+0x88>
  acquire(&tickslock);
    80002d14:	00014517          	auipc	a0,0x14
    80002d18:	3bc50513          	addi	a0,a0,956 # 800170d0 <tickslock>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	eb4080e7          	jalr	-332(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002d24:	00006917          	auipc	s2,0x6
    80002d28:	30c92903          	lw	s2,780(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    80002d2c:	fcc42783          	lw	a5,-52(s0)
    80002d30:	cf85                	beqz	a5,80002d68 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d32:	00014997          	auipc	s3,0x14
    80002d36:	39e98993          	addi	s3,s3,926 # 800170d0 <tickslock>
    80002d3a:	00006497          	auipc	s1,0x6
    80002d3e:	2f648493          	addi	s1,s1,758 # 80009030 <ticks>
    if (myproc()->killed)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	c54080e7          	jalr	-940(ra) # 80001996 <myproc>
    80002d4a:	551c                	lw	a5,40(a0)
    80002d4c:	ef9d                	bnez	a5,80002d8a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d4e:	85ce                	mv	a1,s3
    80002d50:	8526                	mv	a0,s1
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	304080e7          	jalr	772(ra) # 80002056 <sleep>
  while (ticks - ticks0 < n)
    80002d5a:	409c                	lw	a5,0(s1)
    80002d5c:	412787bb          	subw	a5,a5,s2
    80002d60:	fcc42703          	lw	a4,-52(s0)
    80002d64:	fce7efe3          	bltu	a5,a4,80002d42 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d68:	00014517          	auipc	a0,0x14
    80002d6c:	36850513          	addi	a0,a0,872 # 800170d0 <tickslock>
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	f14080e7          	jalr	-236(ra) # 80000c84 <release>
  return 0;
    80002d78:	4781                	li	a5,0
}
    80002d7a:	853e                	mv	a0,a5
    80002d7c:	70e2                	ld	ra,56(sp)
    80002d7e:	7442                	ld	s0,48(sp)
    80002d80:	74a2                	ld	s1,40(sp)
    80002d82:	7902                	ld	s2,32(sp)
    80002d84:	69e2                	ld	s3,24(sp)
    80002d86:	6121                	addi	sp,sp,64
    80002d88:	8082                	ret
      release(&tickslock);
    80002d8a:	00014517          	auipc	a0,0x14
    80002d8e:	34650513          	addi	a0,a0,838 # 800170d0 <tickslock>
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	ef2080e7          	jalr	-270(ra) # 80000c84 <release>
      return -1;
    80002d9a:	57fd                	li	a5,-1
    80002d9c:	bff9                	j	80002d7a <sys_sleep+0x88>

0000000080002d9e <sys_kill>:

uint64
sys_kill(void)
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80002da6:	fec40593          	addi	a1,s0,-20
    80002daa:	4501                	li	a0,0
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	d86080e7          	jalr	-634(ra) # 80002b32 <argint>
    80002db4:	87aa                	mv	a5,a0
    return -1;
    80002db6:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80002db8:	0007c863          	bltz	a5,80002dc8 <sys_kill+0x2a>
  return kill(pid);
    80002dbc:	fec42503          	lw	a0,-20(s0)
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	5c8080e7          	jalr	1480(ra) # 80002388 <kill>
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dd0:	1101                	addi	sp,sp,-32
    80002dd2:	ec06                	sd	ra,24(sp)
    80002dd4:	e822                	sd	s0,16(sp)
    80002dd6:	e426                	sd	s1,8(sp)
    80002dd8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dda:	00014517          	auipc	a0,0x14
    80002dde:	2f650513          	addi	a0,a0,758 # 800170d0 <tickslock>
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	dee080e7          	jalr	-530(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002dea:	00006497          	auipc	s1,0x6
    80002dee:	2464a483          	lw	s1,582(s1) # 80009030 <ticks>
  release(&tickslock);
    80002df2:	00014517          	auipc	a0,0x14
    80002df6:	2de50513          	addi	a0,a0,734 # 800170d0 <tickslock>
    80002dfa:	ffffe097          	auipc	ra,0xffffe
    80002dfe:	e8a080e7          	jalr	-374(ra) # 80000c84 <release>
  return xticks;
}
    80002e02:	02049513          	slli	a0,s1,0x20
    80002e06:	9101                	srli	a0,a0,0x20
    80002e08:	60e2                	ld	ra,24(sp)
    80002e0a:	6442                	ld	s0,16(sp)
    80002e0c:	64a2                	ld	s1,8(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret

0000000080002e12 <sys_ps>:

uint64
sys_ps(void)
{
    80002e12:	1141                	addi	sp,sp,-16
    80002e14:	e406                	sd	ra,8(sp)
    80002e16:	e022                	sd	s0,0(sp)
    80002e18:	0800                	addi	s0,sp,16

  ps();
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	73a080e7          	jalr	1850(ra) # 80002554 <ps>
  return 0;
}
    80002e22:	4501                	li	a0,0
    80002e24:	60a2                	ld	ra,8(sp)
    80002e26:	6402                	ld	s0,0(sp)
    80002e28:	0141                	addi	sp,sp,16
    80002e2a:	8082                	ret

0000000080002e2c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e2c:	7179                	addi	sp,sp,-48
    80002e2e:	f406                	sd	ra,40(sp)
    80002e30:	f022                	sd	s0,32(sp)
    80002e32:	ec26                	sd	s1,24(sp)
    80002e34:	e84a                	sd	s2,16(sp)
    80002e36:	e44e                	sd	s3,8(sp)
    80002e38:	e052                	sd	s4,0(sp)
    80002e3a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e3c:	00005597          	auipc	a1,0x5
    80002e40:	74458593          	addi	a1,a1,1860 # 80008580 <syscalls+0xb8>
    80002e44:	00014517          	auipc	a0,0x14
    80002e48:	2a450513          	addi	a0,a0,676 # 800170e8 <bcache>
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	cf4080e7          	jalr	-780(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e54:	0001c797          	auipc	a5,0x1c
    80002e58:	29478793          	addi	a5,a5,660 # 8001f0e8 <bcache+0x8000>
    80002e5c:	0001c717          	auipc	a4,0x1c
    80002e60:	4f470713          	addi	a4,a4,1268 # 8001f350 <bcache+0x8268>
    80002e64:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e68:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e6c:	00014497          	auipc	s1,0x14
    80002e70:	29448493          	addi	s1,s1,660 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e74:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e76:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e78:	00005a17          	auipc	s4,0x5
    80002e7c:	710a0a13          	addi	s4,s4,1808 # 80008588 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e80:	2b893783          	ld	a5,696(s2)
    80002e84:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e86:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e8a:	85d2                	mv	a1,s4
    80002e8c:	01048513          	addi	a0,s1,16
    80002e90:	00001097          	auipc	ra,0x1
    80002e94:	4bc080e7          	jalr	1212(ra) # 8000434c <initsleeplock>
    bcache.head.next->prev = b;
    80002e98:	2b893783          	ld	a5,696(s2)
    80002e9c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e9e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ea2:	45848493          	addi	s1,s1,1112
    80002ea6:	fd349de3          	bne	s1,s3,80002e80 <binit+0x54>
  }
}
    80002eaa:	70a2                	ld	ra,40(sp)
    80002eac:	7402                	ld	s0,32(sp)
    80002eae:	64e2                	ld	s1,24(sp)
    80002eb0:	6942                	ld	s2,16(sp)
    80002eb2:	69a2                	ld	s3,8(sp)
    80002eb4:	6a02                	ld	s4,0(sp)
    80002eb6:	6145                	addi	sp,sp,48
    80002eb8:	8082                	ret

0000000080002eba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002eba:	7179                	addi	sp,sp,-48
    80002ebc:	f406                	sd	ra,40(sp)
    80002ebe:	f022                	sd	s0,32(sp)
    80002ec0:	ec26                	sd	s1,24(sp)
    80002ec2:	e84a                	sd	s2,16(sp)
    80002ec4:	e44e                	sd	s3,8(sp)
    80002ec6:	1800                	addi	s0,sp,48
    80002ec8:	892a                	mv	s2,a0
    80002eca:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ecc:	00014517          	auipc	a0,0x14
    80002ed0:	21c50513          	addi	a0,a0,540 # 800170e8 <bcache>
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	cfc080e7          	jalr	-772(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002edc:	0001c497          	auipc	s1,0x1c
    80002ee0:	4c44b483          	ld	s1,1220(s1) # 8001f3a0 <bcache+0x82b8>
    80002ee4:	0001c797          	auipc	a5,0x1c
    80002ee8:	46c78793          	addi	a5,a5,1132 # 8001f350 <bcache+0x8268>
    80002eec:	02f48f63          	beq	s1,a5,80002f2a <bread+0x70>
    80002ef0:	873e                	mv	a4,a5
    80002ef2:	a021                	j	80002efa <bread+0x40>
    80002ef4:	68a4                	ld	s1,80(s1)
    80002ef6:	02e48a63          	beq	s1,a4,80002f2a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002efa:	449c                	lw	a5,8(s1)
    80002efc:	ff279ce3          	bne	a5,s2,80002ef4 <bread+0x3a>
    80002f00:	44dc                	lw	a5,12(s1)
    80002f02:	ff3799e3          	bne	a5,s3,80002ef4 <bread+0x3a>
      b->refcnt++;
    80002f06:	40bc                	lw	a5,64(s1)
    80002f08:	2785                	addiw	a5,a5,1
    80002f0a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	1dc50513          	addi	a0,a0,476 # 800170e8 <bcache>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	d70080e7          	jalr	-656(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f1c:	01048513          	addi	a0,s1,16
    80002f20:	00001097          	auipc	ra,0x1
    80002f24:	466080e7          	jalr	1126(ra) # 80004386 <acquiresleep>
      return b;
    80002f28:	a8b9                	j	80002f86 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f2a:	0001c497          	auipc	s1,0x1c
    80002f2e:	46e4b483          	ld	s1,1134(s1) # 8001f398 <bcache+0x82b0>
    80002f32:	0001c797          	auipc	a5,0x1c
    80002f36:	41e78793          	addi	a5,a5,1054 # 8001f350 <bcache+0x8268>
    80002f3a:	00f48863          	beq	s1,a5,80002f4a <bread+0x90>
    80002f3e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f40:	40bc                	lw	a5,64(s1)
    80002f42:	cf81                	beqz	a5,80002f5a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f44:	64a4                	ld	s1,72(s1)
    80002f46:	fee49de3          	bne	s1,a4,80002f40 <bread+0x86>
  panic("bget: no buffers");
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	64650513          	addi	a0,a0,1606 # 80008590 <syscalls+0xc8>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	5e6080e7          	jalr	1510(ra) # 80000538 <panic>
      b->dev = dev;
    80002f5a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f5e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f62:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f66:	4785                	li	a5,1
    80002f68:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	17e50513          	addi	a0,a0,382 # 800170e8 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	d12080e7          	jalr	-750(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f7a:	01048513          	addi	a0,s1,16
    80002f7e:	00001097          	auipc	ra,0x1
    80002f82:	408080e7          	jalr	1032(ra) # 80004386 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f86:	409c                	lw	a5,0(s1)
    80002f88:	cb89                	beqz	a5,80002f9a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f8a:	8526                	mv	a0,s1
    80002f8c:	70a2                	ld	ra,40(sp)
    80002f8e:	7402                	ld	s0,32(sp)
    80002f90:	64e2                	ld	s1,24(sp)
    80002f92:	6942                	ld	s2,16(sp)
    80002f94:	69a2                	ld	s3,8(sp)
    80002f96:	6145                	addi	sp,sp,48
    80002f98:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f9a:	4581                	li	a1,0
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	00003097          	auipc	ra,0x3
    80002fa2:	f18080e7          	jalr	-232(ra) # 80005eb6 <virtio_disk_rw>
    b->valid = 1;
    80002fa6:	4785                	li	a5,1
    80002fa8:	c09c                	sw	a5,0(s1)
  return b;
    80002faa:	b7c5                	j	80002f8a <bread+0xd0>

0000000080002fac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	e426                	sd	s1,8(sp)
    80002fb4:	1000                	addi	s0,sp,32
    80002fb6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fb8:	0541                	addi	a0,a0,16
    80002fba:	00001097          	auipc	ra,0x1
    80002fbe:	466080e7          	jalr	1126(ra) # 80004420 <holdingsleep>
    80002fc2:	cd01                	beqz	a0,80002fda <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fc4:	4585                	li	a1,1
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	00003097          	auipc	ra,0x3
    80002fcc:	eee080e7          	jalr	-274(ra) # 80005eb6 <virtio_disk_rw>
}
    80002fd0:	60e2                	ld	ra,24(sp)
    80002fd2:	6442                	ld	s0,16(sp)
    80002fd4:	64a2                	ld	s1,8(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret
    panic("bwrite");
    80002fda:	00005517          	auipc	a0,0x5
    80002fde:	5ce50513          	addi	a0,a0,1486 # 800085a8 <syscalls+0xe0>
    80002fe2:	ffffd097          	auipc	ra,0xffffd
    80002fe6:	556080e7          	jalr	1366(ra) # 80000538 <panic>

0000000080002fea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fea:	1101                	addi	sp,sp,-32
    80002fec:	ec06                	sd	ra,24(sp)
    80002fee:	e822                	sd	s0,16(sp)
    80002ff0:	e426                	sd	s1,8(sp)
    80002ff2:	e04a                	sd	s2,0(sp)
    80002ff4:	1000                	addi	s0,sp,32
    80002ff6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ff8:	01050913          	addi	s2,a0,16
    80002ffc:	854a                	mv	a0,s2
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	422080e7          	jalr	1058(ra) # 80004420 <holdingsleep>
    80003006:	c92d                	beqz	a0,80003078 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003008:	854a                	mv	a0,s2
    8000300a:	00001097          	auipc	ra,0x1
    8000300e:	3d2080e7          	jalr	978(ra) # 800043dc <releasesleep>

  acquire(&bcache.lock);
    80003012:	00014517          	auipc	a0,0x14
    80003016:	0d650513          	addi	a0,a0,214 # 800170e8 <bcache>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	bb6080e7          	jalr	-1098(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003022:	40bc                	lw	a5,64(s1)
    80003024:	37fd                	addiw	a5,a5,-1
    80003026:	0007871b          	sext.w	a4,a5
    8000302a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000302c:	eb05                	bnez	a4,8000305c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000302e:	68bc                	ld	a5,80(s1)
    80003030:	64b8                	ld	a4,72(s1)
    80003032:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003034:	64bc                	ld	a5,72(s1)
    80003036:	68b8                	ld	a4,80(s1)
    80003038:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000303a:	0001c797          	auipc	a5,0x1c
    8000303e:	0ae78793          	addi	a5,a5,174 # 8001f0e8 <bcache+0x8000>
    80003042:	2b87b703          	ld	a4,696(a5)
    80003046:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003048:	0001c717          	auipc	a4,0x1c
    8000304c:	30870713          	addi	a4,a4,776 # 8001f350 <bcache+0x8268>
    80003050:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003052:	2b87b703          	ld	a4,696(a5)
    80003056:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003058:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000305c:	00014517          	auipc	a0,0x14
    80003060:	08c50513          	addi	a0,a0,140 # 800170e8 <bcache>
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	c20080e7          	jalr	-992(ra) # 80000c84 <release>
}
    8000306c:	60e2                	ld	ra,24(sp)
    8000306e:	6442                	ld	s0,16(sp)
    80003070:	64a2                	ld	s1,8(sp)
    80003072:	6902                	ld	s2,0(sp)
    80003074:	6105                	addi	sp,sp,32
    80003076:	8082                	ret
    panic("brelse");
    80003078:	00005517          	auipc	a0,0x5
    8000307c:	53850513          	addi	a0,a0,1336 # 800085b0 <syscalls+0xe8>
    80003080:	ffffd097          	auipc	ra,0xffffd
    80003084:	4b8080e7          	jalr	1208(ra) # 80000538 <panic>

0000000080003088 <bpin>:

void
bpin(struct buf *b) {
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003094:	00014517          	auipc	a0,0x14
    80003098:	05450513          	addi	a0,a0,84 # 800170e8 <bcache>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	b34080e7          	jalr	-1228(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800030a4:	40bc                	lw	a5,64(s1)
    800030a6:	2785                	addiw	a5,a5,1
    800030a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	03e50513          	addi	a0,a0,62 # 800170e8 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	bd2080e7          	jalr	-1070(ra) # 80000c84 <release>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6105                	addi	sp,sp,32
    800030c2:	8082                	ret

00000000800030c4 <bunpin>:

void
bunpin(struct buf *b) {
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	e426                	sd	s1,8(sp)
    800030cc:	1000                	addi	s0,sp,32
    800030ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	01850513          	addi	a0,a0,24 # 800170e8 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	af8080e7          	jalr	-1288(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800030e0:	40bc                	lw	a5,64(s1)
    800030e2:	37fd                	addiw	a5,a5,-1
    800030e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030e6:	00014517          	auipc	a0,0x14
    800030ea:	00250513          	addi	a0,a0,2 # 800170e8 <bcache>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	b96080e7          	jalr	-1130(ra) # 80000c84 <release>
}
    800030f6:	60e2                	ld	ra,24(sp)
    800030f8:	6442                	ld	s0,16(sp)
    800030fa:	64a2                	ld	s1,8(sp)
    800030fc:	6105                	addi	sp,sp,32
    800030fe:	8082                	ret

0000000080003100 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003100:	1101                	addi	sp,sp,-32
    80003102:	ec06                	sd	ra,24(sp)
    80003104:	e822                	sd	s0,16(sp)
    80003106:	e426                	sd	s1,8(sp)
    80003108:	e04a                	sd	s2,0(sp)
    8000310a:	1000                	addi	s0,sp,32
    8000310c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000310e:	00d5d59b          	srliw	a1,a1,0xd
    80003112:	0001c797          	auipc	a5,0x1c
    80003116:	6b27a783          	lw	a5,1714(a5) # 8001f7c4 <sb+0x1c>
    8000311a:	9dbd                	addw	a1,a1,a5
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	d9e080e7          	jalr	-610(ra) # 80002eba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003124:	0074f713          	andi	a4,s1,7
    80003128:	4785                	li	a5,1
    8000312a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000312e:	14ce                	slli	s1,s1,0x33
    80003130:	90d9                	srli	s1,s1,0x36
    80003132:	00950733          	add	a4,a0,s1
    80003136:	05874703          	lbu	a4,88(a4)
    8000313a:	00e7f6b3          	and	a3,a5,a4
    8000313e:	c69d                	beqz	a3,8000316c <bfree+0x6c>
    80003140:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003142:	94aa                	add	s1,s1,a0
    80003144:	fff7c793          	not	a5,a5
    80003148:	8ff9                	and	a5,a5,a4
    8000314a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000314e:	00001097          	auipc	ra,0x1
    80003152:	118080e7          	jalr	280(ra) # 80004266 <log_write>
  brelse(bp);
    80003156:	854a                	mv	a0,s2
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	e92080e7          	jalr	-366(ra) # 80002fea <brelse>
}
    80003160:	60e2                	ld	ra,24(sp)
    80003162:	6442                	ld	s0,16(sp)
    80003164:	64a2                	ld	s1,8(sp)
    80003166:	6902                	ld	s2,0(sp)
    80003168:	6105                	addi	sp,sp,32
    8000316a:	8082                	ret
    panic("freeing free block");
    8000316c:	00005517          	auipc	a0,0x5
    80003170:	44c50513          	addi	a0,a0,1100 # 800085b8 <syscalls+0xf0>
    80003174:	ffffd097          	auipc	ra,0xffffd
    80003178:	3c4080e7          	jalr	964(ra) # 80000538 <panic>

000000008000317c <balloc>:
{
    8000317c:	711d                	addi	sp,sp,-96
    8000317e:	ec86                	sd	ra,88(sp)
    80003180:	e8a2                	sd	s0,80(sp)
    80003182:	e4a6                	sd	s1,72(sp)
    80003184:	e0ca                	sd	s2,64(sp)
    80003186:	fc4e                	sd	s3,56(sp)
    80003188:	f852                	sd	s4,48(sp)
    8000318a:	f456                	sd	s5,40(sp)
    8000318c:	f05a                	sd	s6,32(sp)
    8000318e:	ec5e                	sd	s7,24(sp)
    80003190:	e862                	sd	s8,16(sp)
    80003192:	e466                	sd	s9,8(sp)
    80003194:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003196:	0001c797          	auipc	a5,0x1c
    8000319a:	6167a783          	lw	a5,1558(a5) # 8001f7ac <sb+0x4>
    8000319e:	cbd1                	beqz	a5,80003232 <balloc+0xb6>
    800031a0:	8baa                	mv	s7,a0
    800031a2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031a4:	0001cb17          	auipc	s6,0x1c
    800031a8:	604b0b13          	addi	s6,s6,1540 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ac:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031ae:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031b2:	6c89                	lui	s9,0x2
    800031b4:	a831                	j	800031d0 <balloc+0x54>
    brelse(bp);
    800031b6:	854a                	mv	a0,s2
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	e32080e7          	jalr	-462(ra) # 80002fea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031c0:	015c87bb          	addw	a5,s9,s5
    800031c4:	00078a9b          	sext.w	s5,a5
    800031c8:	004b2703          	lw	a4,4(s6)
    800031cc:	06eaf363          	bgeu	s5,a4,80003232 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031d0:	41fad79b          	sraiw	a5,s5,0x1f
    800031d4:	0137d79b          	srliw	a5,a5,0x13
    800031d8:	015787bb          	addw	a5,a5,s5
    800031dc:	40d7d79b          	sraiw	a5,a5,0xd
    800031e0:	01cb2583          	lw	a1,28(s6)
    800031e4:	9dbd                	addw	a1,a1,a5
    800031e6:	855e                	mv	a0,s7
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	cd2080e7          	jalr	-814(ra) # 80002eba <bread>
    800031f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f2:	004b2503          	lw	a0,4(s6)
    800031f6:	000a849b          	sext.w	s1,s5
    800031fa:	8662                	mv	a2,s8
    800031fc:	faa4fde3          	bgeu	s1,a0,800031b6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003200:	41f6579b          	sraiw	a5,a2,0x1f
    80003204:	01d7d69b          	srliw	a3,a5,0x1d
    80003208:	00c6873b          	addw	a4,a3,a2
    8000320c:	00777793          	andi	a5,a4,7
    80003210:	9f95                	subw	a5,a5,a3
    80003212:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003216:	4037571b          	sraiw	a4,a4,0x3
    8000321a:	00e906b3          	add	a3,s2,a4
    8000321e:	0586c683          	lbu	a3,88(a3)
    80003222:	00d7f5b3          	and	a1,a5,a3
    80003226:	cd91                	beqz	a1,80003242 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003228:	2605                	addiw	a2,a2,1
    8000322a:	2485                	addiw	s1,s1,1
    8000322c:	fd4618e3          	bne	a2,s4,800031fc <balloc+0x80>
    80003230:	b759                	j	800031b6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003232:	00005517          	auipc	a0,0x5
    80003236:	39e50513          	addi	a0,a0,926 # 800085d0 <syscalls+0x108>
    8000323a:	ffffd097          	auipc	ra,0xffffd
    8000323e:	2fe080e7          	jalr	766(ra) # 80000538 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003242:	974a                	add	a4,a4,s2
    80003244:	8fd5                	or	a5,a5,a3
    80003246:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000324a:	854a                	mv	a0,s2
    8000324c:	00001097          	auipc	ra,0x1
    80003250:	01a080e7          	jalr	26(ra) # 80004266 <log_write>
        brelse(bp);
    80003254:	854a                	mv	a0,s2
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	d94080e7          	jalr	-620(ra) # 80002fea <brelse>
  bp = bread(dev, bno);
    8000325e:	85a6                	mv	a1,s1
    80003260:	855e                	mv	a0,s7
    80003262:	00000097          	auipc	ra,0x0
    80003266:	c58080e7          	jalr	-936(ra) # 80002eba <bread>
    8000326a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000326c:	40000613          	li	a2,1024
    80003270:	4581                	li	a1,0
    80003272:	05850513          	addi	a0,a0,88
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	a56080e7          	jalr	-1450(ra) # 80000ccc <memset>
  log_write(bp);
    8000327e:	854a                	mv	a0,s2
    80003280:	00001097          	auipc	ra,0x1
    80003284:	fe6080e7          	jalr	-26(ra) # 80004266 <log_write>
  brelse(bp);
    80003288:	854a                	mv	a0,s2
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	d60080e7          	jalr	-672(ra) # 80002fea <brelse>
}
    80003292:	8526                	mv	a0,s1
    80003294:	60e6                	ld	ra,88(sp)
    80003296:	6446                	ld	s0,80(sp)
    80003298:	64a6                	ld	s1,72(sp)
    8000329a:	6906                	ld	s2,64(sp)
    8000329c:	79e2                	ld	s3,56(sp)
    8000329e:	7a42                	ld	s4,48(sp)
    800032a0:	7aa2                	ld	s5,40(sp)
    800032a2:	7b02                	ld	s6,32(sp)
    800032a4:	6be2                	ld	s7,24(sp)
    800032a6:	6c42                	ld	s8,16(sp)
    800032a8:	6ca2                	ld	s9,8(sp)
    800032aa:	6125                	addi	sp,sp,96
    800032ac:	8082                	ret

00000000800032ae <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032ae:	7179                	addi	sp,sp,-48
    800032b0:	f406                	sd	ra,40(sp)
    800032b2:	f022                	sd	s0,32(sp)
    800032b4:	ec26                	sd	s1,24(sp)
    800032b6:	e84a                	sd	s2,16(sp)
    800032b8:	e44e                	sd	s3,8(sp)
    800032ba:	e052                	sd	s4,0(sp)
    800032bc:	1800                	addi	s0,sp,48
    800032be:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032c0:	47ad                	li	a5,11
    800032c2:	04b7fe63          	bgeu	a5,a1,8000331e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032c6:	ff45849b          	addiw	s1,a1,-12
    800032ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032ce:	0ff00793          	li	a5,255
    800032d2:	0ae7e363          	bltu	a5,a4,80003378 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032d6:	08052583          	lw	a1,128(a0)
    800032da:	c5ad                	beqz	a1,80003344 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032dc:	00092503          	lw	a0,0(s2)
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	bda080e7          	jalr	-1062(ra) # 80002eba <bread>
    800032e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ee:	02049593          	slli	a1,s1,0x20
    800032f2:	9181                	srli	a1,a1,0x20
    800032f4:	058a                	slli	a1,a1,0x2
    800032f6:	00b784b3          	add	s1,a5,a1
    800032fa:	0004a983          	lw	s3,0(s1)
    800032fe:	04098d63          	beqz	s3,80003358 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003302:	8552                	mv	a0,s4
    80003304:	00000097          	auipc	ra,0x0
    80003308:	ce6080e7          	jalr	-794(ra) # 80002fea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000330c:	854e                	mv	a0,s3
    8000330e:	70a2                	ld	ra,40(sp)
    80003310:	7402                	ld	s0,32(sp)
    80003312:	64e2                	ld	s1,24(sp)
    80003314:	6942                	ld	s2,16(sp)
    80003316:	69a2                	ld	s3,8(sp)
    80003318:	6a02                	ld	s4,0(sp)
    8000331a:	6145                	addi	sp,sp,48
    8000331c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000331e:	02059493          	slli	s1,a1,0x20
    80003322:	9081                	srli	s1,s1,0x20
    80003324:	048a                	slli	s1,s1,0x2
    80003326:	94aa                	add	s1,s1,a0
    80003328:	0504a983          	lw	s3,80(s1)
    8000332c:	fe0990e3          	bnez	s3,8000330c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003330:	4108                	lw	a0,0(a0)
    80003332:	00000097          	auipc	ra,0x0
    80003336:	e4a080e7          	jalr	-438(ra) # 8000317c <balloc>
    8000333a:	0005099b          	sext.w	s3,a0
    8000333e:	0534a823          	sw	s3,80(s1)
    80003342:	b7e9                	j	8000330c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003344:	4108                	lw	a0,0(a0)
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	e36080e7          	jalr	-458(ra) # 8000317c <balloc>
    8000334e:	0005059b          	sext.w	a1,a0
    80003352:	08b92023          	sw	a1,128(s2)
    80003356:	b759                	j	800032dc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003358:	00092503          	lw	a0,0(s2)
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	e20080e7          	jalr	-480(ra) # 8000317c <balloc>
    80003364:	0005099b          	sext.w	s3,a0
    80003368:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000336c:	8552                	mv	a0,s4
    8000336e:	00001097          	auipc	ra,0x1
    80003372:	ef8080e7          	jalr	-264(ra) # 80004266 <log_write>
    80003376:	b771                	j	80003302 <bmap+0x54>
  panic("bmap: out of range");
    80003378:	00005517          	auipc	a0,0x5
    8000337c:	27050513          	addi	a0,a0,624 # 800085e8 <syscalls+0x120>
    80003380:	ffffd097          	auipc	ra,0xffffd
    80003384:	1b8080e7          	jalr	440(ra) # 80000538 <panic>

0000000080003388 <iget>:
{
    80003388:	7179                	addi	sp,sp,-48
    8000338a:	f406                	sd	ra,40(sp)
    8000338c:	f022                	sd	s0,32(sp)
    8000338e:	ec26                	sd	s1,24(sp)
    80003390:	e84a                	sd	s2,16(sp)
    80003392:	e44e                	sd	s3,8(sp)
    80003394:	e052                	sd	s4,0(sp)
    80003396:	1800                	addi	s0,sp,48
    80003398:	89aa                	mv	s3,a0
    8000339a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000339c:	0001c517          	auipc	a0,0x1c
    800033a0:	42c50513          	addi	a0,a0,1068 # 8001f7c8 <itable>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	82c080e7          	jalr	-2004(ra) # 80000bd0 <acquire>
  empty = 0;
    800033ac:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ae:	0001c497          	auipc	s1,0x1c
    800033b2:	43248493          	addi	s1,s1,1074 # 8001f7e0 <itable+0x18>
    800033b6:	0001e697          	auipc	a3,0x1e
    800033ba:	eba68693          	addi	a3,a3,-326 # 80021270 <log>
    800033be:	a039                	j	800033cc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033c0:	02090b63          	beqz	s2,800033f6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033c4:	08848493          	addi	s1,s1,136
    800033c8:	02d48a63          	beq	s1,a3,800033fc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033cc:	449c                	lw	a5,8(s1)
    800033ce:	fef059e3          	blez	a5,800033c0 <iget+0x38>
    800033d2:	4098                	lw	a4,0(s1)
    800033d4:	ff3716e3          	bne	a4,s3,800033c0 <iget+0x38>
    800033d8:	40d8                	lw	a4,4(s1)
    800033da:	ff4713e3          	bne	a4,s4,800033c0 <iget+0x38>
      ip->ref++;
    800033de:	2785                	addiw	a5,a5,1
    800033e0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033e2:	0001c517          	auipc	a0,0x1c
    800033e6:	3e650513          	addi	a0,a0,998 # 8001f7c8 <itable>
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	89a080e7          	jalr	-1894(ra) # 80000c84 <release>
      return ip;
    800033f2:	8926                	mv	s2,s1
    800033f4:	a03d                	j	80003422 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033f6:	f7f9                	bnez	a5,800033c4 <iget+0x3c>
    800033f8:	8926                	mv	s2,s1
    800033fa:	b7e9                	j	800033c4 <iget+0x3c>
  if(empty == 0)
    800033fc:	02090c63          	beqz	s2,80003434 <iget+0xac>
  ip->dev = dev;
    80003400:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003404:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003408:	4785                	li	a5,1
    8000340a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000340e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003412:	0001c517          	auipc	a0,0x1c
    80003416:	3b650513          	addi	a0,a0,950 # 8001f7c8 <itable>
    8000341a:	ffffe097          	auipc	ra,0xffffe
    8000341e:	86a080e7          	jalr	-1942(ra) # 80000c84 <release>
}
    80003422:	854a                	mv	a0,s2
    80003424:	70a2                	ld	ra,40(sp)
    80003426:	7402                	ld	s0,32(sp)
    80003428:	64e2                	ld	s1,24(sp)
    8000342a:	6942                	ld	s2,16(sp)
    8000342c:	69a2                	ld	s3,8(sp)
    8000342e:	6a02                	ld	s4,0(sp)
    80003430:	6145                	addi	sp,sp,48
    80003432:	8082                	ret
    panic("iget: no inodes");
    80003434:	00005517          	auipc	a0,0x5
    80003438:	1cc50513          	addi	a0,a0,460 # 80008600 <syscalls+0x138>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	0fc080e7          	jalr	252(ra) # 80000538 <panic>

0000000080003444 <fsinit>:
fsinit(int dev) {
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	1800                	addi	s0,sp,48
    80003452:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003454:	4585                	li	a1,1
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	a64080e7          	jalr	-1436(ra) # 80002eba <bread>
    8000345e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003460:	0001c997          	auipc	s3,0x1c
    80003464:	34898993          	addi	s3,s3,840 # 8001f7a8 <sb>
    80003468:	02000613          	li	a2,32
    8000346c:	05850593          	addi	a1,a0,88
    80003470:	854e                	mv	a0,s3
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	8b6080e7          	jalr	-1866(ra) # 80000d28 <memmove>
  brelse(bp);
    8000347a:	8526                	mv	a0,s1
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	b6e080e7          	jalr	-1170(ra) # 80002fea <brelse>
  if(sb.magic != FSMAGIC)
    80003484:	0009a703          	lw	a4,0(s3)
    80003488:	102037b7          	lui	a5,0x10203
    8000348c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003490:	02f71263          	bne	a4,a5,800034b4 <fsinit+0x70>
  initlog(dev, &sb);
    80003494:	0001c597          	auipc	a1,0x1c
    80003498:	31458593          	addi	a1,a1,788 # 8001f7a8 <sb>
    8000349c:	854a                	mv	a0,s2
    8000349e:	00001097          	auipc	ra,0x1
    800034a2:	b4c080e7          	jalr	-1204(ra) # 80003fea <initlog>
}
    800034a6:	70a2                	ld	ra,40(sp)
    800034a8:	7402                	ld	s0,32(sp)
    800034aa:	64e2                	ld	s1,24(sp)
    800034ac:	6942                	ld	s2,16(sp)
    800034ae:	69a2                	ld	s3,8(sp)
    800034b0:	6145                	addi	sp,sp,48
    800034b2:	8082                	ret
    panic("invalid file system");
    800034b4:	00005517          	auipc	a0,0x5
    800034b8:	15c50513          	addi	a0,a0,348 # 80008610 <syscalls+0x148>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	07c080e7          	jalr	124(ra) # 80000538 <panic>

00000000800034c4 <iinit>:
{
    800034c4:	7179                	addi	sp,sp,-48
    800034c6:	f406                	sd	ra,40(sp)
    800034c8:	f022                	sd	s0,32(sp)
    800034ca:	ec26                	sd	s1,24(sp)
    800034cc:	e84a                	sd	s2,16(sp)
    800034ce:	e44e                	sd	s3,8(sp)
    800034d0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034d2:	00005597          	auipc	a1,0x5
    800034d6:	15658593          	addi	a1,a1,342 # 80008628 <syscalls+0x160>
    800034da:	0001c517          	auipc	a0,0x1c
    800034de:	2ee50513          	addi	a0,a0,750 # 8001f7c8 <itable>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	65e080e7          	jalr	1630(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034ea:	0001c497          	auipc	s1,0x1c
    800034ee:	30648493          	addi	s1,s1,774 # 8001f7f0 <itable+0x28>
    800034f2:	0001e997          	auipc	s3,0x1e
    800034f6:	d8e98993          	addi	s3,s3,-626 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034fa:	00005917          	auipc	s2,0x5
    800034fe:	13690913          	addi	s2,s2,310 # 80008630 <syscalls+0x168>
    80003502:	85ca                	mv	a1,s2
    80003504:	8526                	mv	a0,s1
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	e46080e7          	jalr	-442(ra) # 8000434c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000350e:	08848493          	addi	s1,s1,136
    80003512:	ff3498e3          	bne	s1,s3,80003502 <iinit+0x3e>
}
    80003516:	70a2                	ld	ra,40(sp)
    80003518:	7402                	ld	s0,32(sp)
    8000351a:	64e2                	ld	s1,24(sp)
    8000351c:	6942                	ld	s2,16(sp)
    8000351e:	69a2                	ld	s3,8(sp)
    80003520:	6145                	addi	sp,sp,48
    80003522:	8082                	ret

0000000080003524 <ialloc>:
{
    80003524:	715d                	addi	sp,sp,-80
    80003526:	e486                	sd	ra,72(sp)
    80003528:	e0a2                	sd	s0,64(sp)
    8000352a:	fc26                	sd	s1,56(sp)
    8000352c:	f84a                	sd	s2,48(sp)
    8000352e:	f44e                	sd	s3,40(sp)
    80003530:	f052                	sd	s4,32(sp)
    80003532:	ec56                	sd	s5,24(sp)
    80003534:	e85a                	sd	s6,16(sp)
    80003536:	e45e                	sd	s7,8(sp)
    80003538:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000353a:	0001c717          	auipc	a4,0x1c
    8000353e:	27a72703          	lw	a4,634(a4) # 8001f7b4 <sb+0xc>
    80003542:	4785                	li	a5,1
    80003544:	04e7fa63          	bgeu	a5,a4,80003598 <ialloc+0x74>
    80003548:	8aaa                	mv	s5,a0
    8000354a:	8bae                	mv	s7,a1
    8000354c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000354e:	0001ca17          	auipc	s4,0x1c
    80003552:	25aa0a13          	addi	s4,s4,602 # 8001f7a8 <sb>
    80003556:	00048b1b          	sext.w	s6,s1
    8000355a:	0044d793          	srli	a5,s1,0x4
    8000355e:	018a2583          	lw	a1,24(s4)
    80003562:	9dbd                	addw	a1,a1,a5
    80003564:	8556                	mv	a0,s5
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	954080e7          	jalr	-1708(ra) # 80002eba <bread>
    8000356e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003570:	05850993          	addi	s3,a0,88
    80003574:	00f4f793          	andi	a5,s1,15
    80003578:	079a                	slli	a5,a5,0x6
    8000357a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000357c:	00099783          	lh	a5,0(s3)
    80003580:	c785                	beqz	a5,800035a8 <ialloc+0x84>
    brelse(bp);
    80003582:	00000097          	auipc	ra,0x0
    80003586:	a68080e7          	jalr	-1432(ra) # 80002fea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000358a:	0485                	addi	s1,s1,1
    8000358c:	00ca2703          	lw	a4,12(s4)
    80003590:	0004879b          	sext.w	a5,s1
    80003594:	fce7e1e3          	bltu	a5,a4,80003556 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003598:	00005517          	auipc	a0,0x5
    8000359c:	0a050513          	addi	a0,a0,160 # 80008638 <syscalls+0x170>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	f98080e7          	jalr	-104(ra) # 80000538 <panic>
      memset(dip, 0, sizeof(*dip));
    800035a8:	04000613          	li	a2,64
    800035ac:	4581                	li	a1,0
    800035ae:	854e                	mv	a0,s3
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	71c080e7          	jalr	1820(ra) # 80000ccc <memset>
      dip->type = type;
    800035b8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035bc:	854a                	mv	a0,s2
    800035be:	00001097          	auipc	ra,0x1
    800035c2:	ca8080e7          	jalr	-856(ra) # 80004266 <log_write>
      brelse(bp);
    800035c6:	854a                	mv	a0,s2
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	a22080e7          	jalr	-1502(ra) # 80002fea <brelse>
      return iget(dev, inum);
    800035d0:	85da                	mv	a1,s6
    800035d2:	8556                	mv	a0,s5
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	db4080e7          	jalr	-588(ra) # 80003388 <iget>
}
    800035dc:	60a6                	ld	ra,72(sp)
    800035de:	6406                	ld	s0,64(sp)
    800035e0:	74e2                	ld	s1,56(sp)
    800035e2:	7942                	ld	s2,48(sp)
    800035e4:	79a2                	ld	s3,40(sp)
    800035e6:	7a02                	ld	s4,32(sp)
    800035e8:	6ae2                	ld	s5,24(sp)
    800035ea:	6b42                	ld	s6,16(sp)
    800035ec:	6ba2                	ld	s7,8(sp)
    800035ee:	6161                	addi	sp,sp,80
    800035f0:	8082                	ret

00000000800035f2 <iupdate>:
{
    800035f2:	1101                	addi	sp,sp,-32
    800035f4:	ec06                	sd	ra,24(sp)
    800035f6:	e822                	sd	s0,16(sp)
    800035f8:	e426                	sd	s1,8(sp)
    800035fa:	e04a                	sd	s2,0(sp)
    800035fc:	1000                	addi	s0,sp,32
    800035fe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003600:	415c                	lw	a5,4(a0)
    80003602:	0047d79b          	srliw	a5,a5,0x4
    80003606:	0001c597          	auipc	a1,0x1c
    8000360a:	1ba5a583          	lw	a1,442(a1) # 8001f7c0 <sb+0x18>
    8000360e:	9dbd                	addw	a1,a1,a5
    80003610:	4108                	lw	a0,0(a0)
    80003612:	00000097          	auipc	ra,0x0
    80003616:	8a8080e7          	jalr	-1880(ra) # 80002eba <bread>
    8000361a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000361c:	05850793          	addi	a5,a0,88
    80003620:	40c8                	lw	a0,4(s1)
    80003622:	893d                	andi	a0,a0,15
    80003624:	051a                	slli	a0,a0,0x6
    80003626:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003628:	04449703          	lh	a4,68(s1)
    8000362c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003630:	04649703          	lh	a4,70(s1)
    80003634:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003638:	04849703          	lh	a4,72(s1)
    8000363c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003640:	04a49703          	lh	a4,74(s1)
    80003644:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003648:	44f8                	lw	a4,76(s1)
    8000364a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000364c:	03400613          	li	a2,52
    80003650:	05048593          	addi	a1,s1,80
    80003654:	0531                	addi	a0,a0,12
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	6d2080e7          	jalr	1746(ra) # 80000d28 <memmove>
  log_write(bp);
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	c06080e7          	jalr	-1018(ra) # 80004266 <log_write>
  brelse(bp);
    80003668:	854a                	mv	a0,s2
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	980080e7          	jalr	-1664(ra) # 80002fea <brelse>
}
    80003672:	60e2                	ld	ra,24(sp)
    80003674:	6442                	ld	s0,16(sp)
    80003676:	64a2                	ld	s1,8(sp)
    80003678:	6902                	ld	s2,0(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret

000000008000367e <idup>:
{
    8000367e:	1101                	addi	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	1000                	addi	s0,sp,32
    80003688:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000368a:	0001c517          	auipc	a0,0x1c
    8000368e:	13e50513          	addi	a0,a0,318 # 8001f7c8 <itable>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	53e080e7          	jalr	1342(ra) # 80000bd0 <acquire>
  ip->ref++;
    8000369a:	449c                	lw	a5,8(s1)
    8000369c:	2785                	addiw	a5,a5,1
    8000369e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036a0:	0001c517          	auipc	a0,0x1c
    800036a4:	12850513          	addi	a0,a0,296 # 8001f7c8 <itable>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	5dc080e7          	jalr	1500(ra) # 80000c84 <release>
}
    800036b0:	8526                	mv	a0,s1
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6105                	addi	sp,sp,32
    800036ba:	8082                	ret

00000000800036bc <ilock>:
{
    800036bc:	1101                	addi	sp,sp,-32
    800036be:	ec06                	sd	ra,24(sp)
    800036c0:	e822                	sd	s0,16(sp)
    800036c2:	e426                	sd	s1,8(sp)
    800036c4:	e04a                	sd	s2,0(sp)
    800036c6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036c8:	c115                	beqz	a0,800036ec <ilock+0x30>
    800036ca:	84aa                	mv	s1,a0
    800036cc:	451c                	lw	a5,8(a0)
    800036ce:	00f05f63          	blez	a5,800036ec <ilock+0x30>
  acquiresleep(&ip->lock);
    800036d2:	0541                	addi	a0,a0,16
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	cb2080e7          	jalr	-846(ra) # 80004386 <acquiresleep>
  if(ip->valid == 0){
    800036dc:	40bc                	lw	a5,64(s1)
    800036de:	cf99                	beqz	a5,800036fc <ilock+0x40>
}
    800036e0:	60e2                	ld	ra,24(sp)
    800036e2:	6442                	ld	s0,16(sp)
    800036e4:	64a2                	ld	s1,8(sp)
    800036e6:	6902                	ld	s2,0(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret
    panic("ilock");
    800036ec:	00005517          	auipc	a0,0x5
    800036f0:	f6450513          	addi	a0,a0,-156 # 80008650 <syscalls+0x188>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	e44080e7          	jalr	-444(ra) # 80000538 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036fc:	40dc                	lw	a5,4(s1)
    800036fe:	0047d79b          	srliw	a5,a5,0x4
    80003702:	0001c597          	auipc	a1,0x1c
    80003706:	0be5a583          	lw	a1,190(a1) # 8001f7c0 <sb+0x18>
    8000370a:	9dbd                	addw	a1,a1,a5
    8000370c:	4088                	lw	a0,0(s1)
    8000370e:	fffff097          	auipc	ra,0xfffff
    80003712:	7ac080e7          	jalr	1964(ra) # 80002eba <bread>
    80003716:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003718:	05850593          	addi	a1,a0,88
    8000371c:	40dc                	lw	a5,4(s1)
    8000371e:	8bbd                	andi	a5,a5,15
    80003720:	079a                	slli	a5,a5,0x6
    80003722:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003724:	00059783          	lh	a5,0(a1)
    80003728:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000372c:	00259783          	lh	a5,2(a1)
    80003730:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003734:	00459783          	lh	a5,4(a1)
    80003738:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000373c:	00659783          	lh	a5,6(a1)
    80003740:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003744:	459c                	lw	a5,8(a1)
    80003746:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003748:	03400613          	li	a2,52
    8000374c:	05b1                	addi	a1,a1,12
    8000374e:	05048513          	addi	a0,s1,80
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	5d6080e7          	jalr	1494(ra) # 80000d28 <memmove>
    brelse(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	88e080e7          	jalr	-1906(ra) # 80002fea <brelse>
    ip->valid = 1;
    80003764:	4785                	li	a5,1
    80003766:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003768:	04449783          	lh	a5,68(s1)
    8000376c:	fbb5                	bnez	a5,800036e0 <ilock+0x24>
      panic("ilock: no type");
    8000376e:	00005517          	auipc	a0,0x5
    80003772:	eea50513          	addi	a0,a0,-278 # 80008658 <syscalls+0x190>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	dc2080e7          	jalr	-574(ra) # 80000538 <panic>

000000008000377e <iunlock>:
{
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	e04a                	sd	s2,0(sp)
    80003788:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000378a:	c905                	beqz	a0,800037ba <iunlock+0x3c>
    8000378c:	84aa                	mv	s1,a0
    8000378e:	01050913          	addi	s2,a0,16
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	c8c080e7          	jalr	-884(ra) # 80004420 <holdingsleep>
    8000379c:	cd19                	beqz	a0,800037ba <iunlock+0x3c>
    8000379e:	449c                	lw	a5,8(s1)
    800037a0:	00f05d63          	blez	a5,800037ba <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037a4:	854a                	mv	a0,s2
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	c36080e7          	jalr	-970(ra) # 800043dc <releasesleep>
}
    800037ae:	60e2                	ld	ra,24(sp)
    800037b0:	6442                	ld	s0,16(sp)
    800037b2:	64a2                	ld	s1,8(sp)
    800037b4:	6902                	ld	s2,0(sp)
    800037b6:	6105                	addi	sp,sp,32
    800037b8:	8082                	ret
    panic("iunlock");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	eae50513          	addi	a0,a0,-338 # 80008668 <syscalls+0x1a0>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d76080e7          	jalr	-650(ra) # 80000538 <panic>

00000000800037ca <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037ca:	7179                	addi	sp,sp,-48
    800037cc:	f406                	sd	ra,40(sp)
    800037ce:	f022                	sd	s0,32(sp)
    800037d0:	ec26                	sd	s1,24(sp)
    800037d2:	e84a                	sd	s2,16(sp)
    800037d4:	e44e                	sd	s3,8(sp)
    800037d6:	e052                	sd	s4,0(sp)
    800037d8:	1800                	addi	s0,sp,48
    800037da:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037dc:	05050493          	addi	s1,a0,80
    800037e0:	08050913          	addi	s2,a0,128
    800037e4:	a021                	j	800037ec <itrunc+0x22>
    800037e6:	0491                	addi	s1,s1,4
    800037e8:	01248d63          	beq	s1,s2,80003802 <itrunc+0x38>
    if(ip->addrs[i]){
    800037ec:	408c                	lw	a1,0(s1)
    800037ee:	dde5                	beqz	a1,800037e6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037f0:	0009a503          	lw	a0,0(s3)
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	90c080e7          	jalr	-1780(ra) # 80003100 <bfree>
      ip->addrs[i] = 0;
    800037fc:	0004a023          	sw	zero,0(s1)
    80003800:	b7dd                	j	800037e6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003802:	0809a583          	lw	a1,128(s3)
    80003806:	e185                	bnez	a1,80003826 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003808:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000380c:	854e                	mv	a0,s3
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	de4080e7          	jalr	-540(ra) # 800035f2 <iupdate>
}
    80003816:	70a2                	ld	ra,40(sp)
    80003818:	7402                	ld	s0,32(sp)
    8000381a:	64e2                	ld	s1,24(sp)
    8000381c:	6942                	ld	s2,16(sp)
    8000381e:	69a2                	ld	s3,8(sp)
    80003820:	6a02                	ld	s4,0(sp)
    80003822:	6145                	addi	sp,sp,48
    80003824:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003826:	0009a503          	lw	a0,0(s3)
    8000382a:	fffff097          	auipc	ra,0xfffff
    8000382e:	690080e7          	jalr	1680(ra) # 80002eba <bread>
    80003832:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003834:	05850493          	addi	s1,a0,88
    80003838:	45850913          	addi	s2,a0,1112
    8000383c:	a021                	j	80003844 <itrunc+0x7a>
    8000383e:	0491                	addi	s1,s1,4
    80003840:	01248b63          	beq	s1,s2,80003856 <itrunc+0x8c>
      if(a[j])
    80003844:	408c                	lw	a1,0(s1)
    80003846:	dde5                	beqz	a1,8000383e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003848:	0009a503          	lw	a0,0(s3)
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	8b4080e7          	jalr	-1868(ra) # 80003100 <bfree>
    80003854:	b7ed                	j	8000383e <itrunc+0x74>
    brelse(bp);
    80003856:	8552                	mv	a0,s4
    80003858:	fffff097          	auipc	ra,0xfffff
    8000385c:	792080e7          	jalr	1938(ra) # 80002fea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003860:	0809a583          	lw	a1,128(s3)
    80003864:	0009a503          	lw	a0,0(s3)
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	898080e7          	jalr	-1896(ra) # 80003100 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003870:	0809a023          	sw	zero,128(s3)
    80003874:	bf51                	j	80003808 <itrunc+0x3e>

0000000080003876 <iput>:
{
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	e426                	sd	s1,8(sp)
    8000387e:	e04a                	sd	s2,0(sp)
    80003880:	1000                	addi	s0,sp,32
    80003882:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003884:	0001c517          	auipc	a0,0x1c
    80003888:	f4450513          	addi	a0,a0,-188 # 8001f7c8 <itable>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	344080e7          	jalr	836(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003894:	4498                	lw	a4,8(s1)
    80003896:	4785                	li	a5,1
    80003898:	02f70363          	beq	a4,a5,800038be <iput+0x48>
  ip->ref--;
    8000389c:	449c                	lw	a5,8(s1)
    8000389e:	37fd                	addiw	a5,a5,-1
    800038a0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038a2:	0001c517          	auipc	a0,0x1c
    800038a6:	f2650513          	addi	a0,a0,-218 # 8001f7c8 <itable>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	3da080e7          	jalr	986(ra) # 80000c84 <release>
}
    800038b2:	60e2                	ld	ra,24(sp)
    800038b4:	6442                	ld	s0,16(sp)
    800038b6:	64a2                	ld	s1,8(sp)
    800038b8:	6902                	ld	s2,0(sp)
    800038ba:	6105                	addi	sp,sp,32
    800038bc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038be:	40bc                	lw	a5,64(s1)
    800038c0:	dff1                	beqz	a5,8000389c <iput+0x26>
    800038c2:	04a49783          	lh	a5,74(s1)
    800038c6:	fbf9                	bnez	a5,8000389c <iput+0x26>
    acquiresleep(&ip->lock);
    800038c8:	01048913          	addi	s2,s1,16
    800038cc:	854a                	mv	a0,s2
    800038ce:	00001097          	auipc	ra,0x1
    800038d2:	ab8080e7          	jalr	-1352(ra) # 80004386 <acquiresleep>
    release(&itable.lock);
    800038d6:	0001c517          	auipc	a0,0x1c
    800038da:	ef250513          	addi	a0,a0,-270 # 8001f7c8 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	3a6080e7          	jalr	934(ra) # 80000c84 <release>
    itrunc(ip);
    800038e6:	8526                	mv	a0,s1
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	ee2080e7          	jalr	-286(ra) # 800037ca <itrunc>
    ip->type = 0;
    800038f0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038f4:	8526                	mv	a0,s1
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	cfc080e7          	jalr	-772(ra) # 800035f2 <iupdate>
    ip->valid = 0;
    800038fe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003902:	854a                	mv	a0,s2
    80003904:	00001097          	auipc	ra,0x1
    80003908:	ad8080e7          	jalr	-1320(ra) # 800043dc <releasesleep>
    acquire(&itable.lock);
    8000390c:	0001c517          	auipc	a0,0x1c
    80003910:	ebc50513          	addi	a0,a0,-324 # 8001f7c8 <itable>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	2bc080e7          	jalr	700(ra) # 80000bd0 <acquire>
    8000391c:	b741                	j	8000389c <iput+0x26>

000000008000391e <iunlockput>:
{
    8000391e:	1101                	addi	sp,sp,-32
    80003920:	ec06                	sd	ra,24(sp)
    80003922:	e822                	sd	s0,16(sp)
    80003924:	e426                	sd	s1,8(sp)
    80003926:	1000                	addi	s0,sp,32
    80003928:	84aa                	mv	s1,a0
  iunlock(ip);
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	e54080e7          	jalr	-428(ra) # 8000377e <iunlock>
  iput(ip);
    80003932:	8526                	mv	a0,s1
    80003934:	00000097          	auipc	ra,0x0
    80003938:	f42080e7          	jalr	-190(ra) # 80003876 <iput>
}
    8000393c:	60e2                	ld	ra,24(sp)
    8000393e:	6442                	ld	s0,16(sp)
    80003940:	64a2                	ld	s1,8(sp)
    80003942:	6105                	addi	sp,sp,32
    80003944:	8082                	ret

0000000080003946 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003946:	1141                	addi	sp,sp,-16
    80003948:	e422                	sd	s0,8(sp)
    8000394a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000394c:	411c                	lw	a5,0(a0)
    8000394e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003950:	415c                	lw	a5,4(a0)
    80003952:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003954:	04451783          	lh	a5,68(a0)
    80003958:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000395c:	04a51783          	lh	a5,74(a0)
    80003960:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003964:	04c56783          	lwu	a5,76(a0)
    80003968:	e99c                	sd	a5,16(a1)
}
    8000396a:	6422                	ld	s0,8(sp)
    8000396c:	0141                	addi	sp,sp,16
    8000396e:	8082                	ret

0000000080003970 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003970:	457c                	lw	a5,76(a0)
    80003972:	0ed7e963          	bltu	a5,a3,80003a64 <readi+0xf4>
{
    80003976:	7159                	addi	sp,sp,-112
    80003978:	f486                	sd	ra,104(sp)
    8000397a:	f0a2                	sd	s0,96(sp)
    8000397c:	eca6                	sd	s1,88(sp)
    8000397e:	e8ca                	sd	s2,80(sp)
    80003980:	e4ce                	sd	s3,72(sp)
    80003982:	e0d2                	sd	s4,64(sp)
    80003984:	fc56                	sd	s5,56(sp)
    80003986:	f85a                	sd	s6,48(sp)
    80003988:	f45e                	sd	s7,40(sp)
    8000398a:	f062                	sd	s8,32(sp)
    8000398c:	ec66                	sd	s9,24(sp)
    8000398e:	e86a                	sd	s10,16(sp)
    80003990:	e46e                	sd	s11,8(sp)
    80003992:	1880                	addi	s0,sp,112
    80003994:	8baa                	mv	s7,a0
    80003996:	8c2e                	mv	s8,a1
    80003998:	8ab2                	mv	s5,a2
    8000399a:	84b6                	mv	s1,a3
    8000399c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000399e:	9f35                	addw	a4,a4,a3
    return 0;
    800039a0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039a2:	0ad76063          	bltu	a4,a3,80003a42 <readi+0xd2>
  if(off + n > ip->size)
    800039a6:	00e7f463          	bgeu	a5,a4,800039ae <readi+0x3e>
    n = ip->size - off;
    800039aa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ae:	0a0b0963          	beqz	s6,80003a60 <readi+0xf0>
    800039b2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039b4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039b8:	5cfd                	li	s9,-1
    800039ba:	a82d                	j	800039f4 <readi+0x84>
    800039bc:	020a1d93          	slli	s11,s4,0x20
    800039c0:	020ddd93          	srli	s11,s11,0x20
    800039c4:	05890793          	addi	a5,s2,88
    800039c8:	86ee                	mv	a3,s11
    800039ca:	963e                	add	a2,a2,a5
    800039cc:	85d6                	mv	a1,s5
    800039ce:	8562                	mv	a0,s8
    800039d0:	fffff097          	auipc	ra,0xfffff
    800039d4:	a2a080e7          	jalr	-1494(ra) # 800023fa <either_copyout>
    800039d8:	05950d63          	beq	a0,s9,80003a32 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039dc:	854a                	mv	a0,s2
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	60c080e7          	jalr	1548(ra) # 80002fea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039e6:	013a09bb          	addw	s3,s4,s3
    800039ea:	009a04bb          	addw	s1,s4,s1
    800039ee:	9aee                	add	s5,s5,s11
    800039f0:	0569f763          	bgeu	s3,s6,80003a3e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039f4:	000ba903          	lw	s2,0(s7)
    800039f8:	00a4d59b          	srliw	a1,s1,0xa
    800039fc:	855e                	mv	a0,s7
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	8b0080e7          	jalr	-1872(ra) # 800032ae <bmap>
    80003a06:	0005059b          	sext.w	a1,a0
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	fffff097          	auipc	ra,0xfffff
    80003a10:	4ae080e7          	jalr	1198(ra) # 80002eba <bread>
    80003a14:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a16:	3ff4f613          	andi	a2,s1,1023
    80003a1a:	40cd07bb          	subw	a5,s10,a2
    80003a1e:	413b073b          	subw	a4,s6,s3
    80003a22:	8a3e                	mv	s4,a5
    80003a24:	2781                	sext.w	a5,a5
    80003a26:	0007069b          	sext.w	a3,a4
    80003a2a:	f8f6f9e3          	bgeu	a3,a5,800039bc <readi+0x4c>
    80003a2e:	8a3a                	mv	s4,a4
    80003a30:	b771                	j	800039bc <readi+0x4c>
      brelse(bp);
    80003a32:	854a                	mv	a0,s2
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	5b6080e7          	jalr	1462(ra) # 80002fea <brelse>
      tot = -1;
    80003a3c:	59fd                	li	s3,-1
  }
  return tot;
    80003a3e:	0009851b          	sext.w	a0,s3
}
    80003a42:	70a6                	ld	ra,104(sp)
    80003a44:	7406                	ld	s0,96(sp)
    80003a46:	64e6                	ld	s1,88(sp)
    80003a48:	6946                	ld	s2,80(sp)
    80003a4a:	69a6                	ld	s3,72(sp)
    80003a4c:	6a06                	ld	s4,64(sp)
    80003a4e:	7ae2                	ld	s5,56(sp)
    80003a50:	7b42                	ld	s6,48(sp)
    80003a52:	7ba2                	ld	s7,40(sp)
    80003a54:	7c02                	ld	s8,32(sp)
    80003a56:	6ce2                	ld	s9,24(sp)
    80003a58:	6d42                	ld	s10,16(sp)
    80003a5a:	6da2                	ld	s11,8(sp)
    80003a5c:	6165                	addi	sp,sp,112
    80003a5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a60:	89da                	mv	s3,s6
    80003a62:	bff1                	j	80003a3e <readi+0xce>
    return 0;
    80003a64:	4501                	li	a0,0
}
    80003a66:	8082                	ret

0000000080003a68 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a68:	457c                	lw	a5,76(a0)
    80003a6a:	10d7e863          	bltu	a5,a3,80003b7a <writei+0x112>
{
    80003a6e:	7159                	addi	sp,sp,-112
    80003a70:	f486                	sd	ra,104(sp)
    80003a72:	f0a2                	sd	s0,96(sp)
    80003a74:	eca6                	sd	s1,88(sp)
    80003a76:	e8ca                	sd	s2,80(sp)
    80003a78:	e4ce                	sd	s3,72(sp)
    80003a7a:	e0d2                	sd	s4,64(sp)
    80003a7c:	fc56                	sd	s5,56(sp)
    80003a7e:	f85a                	sd	s6,48(sp)
    80003a80:	f45e                	sd	s7,40(sp)
    80003a82:	f062                	sd	s8,32(sp)
    80003a84:	ec66                	sd	s9,24(sp)
    80003a86:	e86a                	sd	s10,16(sp)
    80003a88:	e46e                	sd	s11,8(sp)
    80003a8a:	1880                	addi	s0,sp,112
    80003a8c:	8b2a                	mv	s6,a0
    80003a8e:	8c2e                	mv	s8,a1
    80003a90:	8ab2                	mv	s5,a2
    80003a92:	8936                	mv	s2,a3
    80003a94:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a96:	00e687bb          	addw	a5,a3,a4
    80003a9a:	0ed7e263          	bltu	a5,a3,80003b7e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a9e:	00043737          	lui	a4,0x43
    80003aa2:	0ef76063          	bltu	a4,a5,80003b82 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa6:	0c0b8863          	beqz	s7,80003b76 <writei+0x10e>
    80003aaa:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aac:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ab0:	5cfd                	li	s9,-1
    80003ab2:	a091                	j	80003af6 <writei+0x8e>
    80003ab4:	02099d93          	slli	s11,s3,0x20
    80003ab8:	020ddd93          	srli	s11,s11,0x20
    80003abc:	05848793          	addi	a5,s1,88
    80003ac0:	86ee                	mv	a3,s11
    80003ac2:	8656                	mv	a2,s5
    80003ac4:	85e2                	mv	a1,s8
    80003ac6:	953e                	add	a0,a0,a5
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	988080e7          	jalr	-1656(ra) # 80002450 <either_copyin>
    80003ad0:	07950263          	beq	a0,s9,80003b34 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ad4:	8526                	mv	a0,s1
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	790080e7          	jalr	1936(ra) # 80004266 <log_write>
    brelse(bp);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	50a080e7          	jalr	1290(ra) # 80002fea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae8:	01498a3b          	addw	s4,s3,s4
    80003aec:	0129893b          	addw	s2,s3,s2
    80003af0:	9aee                	add	s5,s5,s11
    80003af2:	057a7663          	bgeu	s4,s7,80003b3e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003af6:	000b2483          	lw	s1,0(s6)
    80003afa:	00a9559b          	srliw	a1,s2,0xa
    80003afe:	855a                	mv	a0,s6
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	7ae080e7          	jalr	1966(ra) # 800032ae <bmap>
    80003b08:	0005059b          	sext.w	a1,a0
    80003b0c:	8526                	mv	a0,s1
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	3ac080e7          	jalr	940(ra) # 80002eba <bread>
    80003b16:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b18:	3ff97513          	andi	a0,s2,1023
    80003b1c:	40ad07bb          	subw	a5,s10,a0
    80003b20:	414b873b          	subw	a4,s7,s4
    80003b24:	89be                	mv	s3,a5
    80003b26:	2781                	sext.w	a5,a5
    80003b28:	0007069b          	sext.w	a3,a4
    80003b2c:	f8f6f4e3          	bgeu	a3,a5,80003ab4 <writei+0x4c>
    80003b30:	89ba                	mv	s3,a4
    80003b32:	b749                	j	80003ab4 <writei+0x4c>
      brelse(bp);
    80003b34:	8526                	mv	a0,s1
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	4b4080e7          	jalr	1204(ra) # 80002fea <brelse>
  }

  if(off > ip->size)
    80003b3e:	04cb2783          	lw	a5,76(s6)
    80003b42:	0127f463          	bgeu	a5,s2,80003b4a <writei+0xe2>
    ip->size = off;
    80003b46:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b4a:	855a                	mv	a0,s6
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	aa6080e7          	jalr	-1370(ra) # 800035f2 <iupdate>

  return tot;
    80003b54:	000a051b          	sext.w	a0,s4
}
    80003b58:	70a6                	ld	ra,104(sp)
    80003b5a:	7406                	ld	s0,96(sp)
    80003b5c:	64e6                	ld	s1,88(sp)
    80003b5e:	6946                	ld	s2,80(sp)
    80003b60:	69a6                	ld	s3,72(sp)
    80003b62:	6a06                	ld	s4,64(sp)
    80003b64:	7ae2                	ld	s5,56(sp)
    80003b66:	7b42                	ld	s6,48(sp)
    80003b68:	7ba2                	ld	s7,40(sp)
    80003b6a:	7c02                	ld	s8,32(sp)
    80003b6c:	6ce2                	ld	s9,24(sp)
    80003b6e:	6d42                	ld	s10,16(sp)
    80003b70:	6da2                	ld	s11,8(sp)
    80003b72:	6165                	addi	sp,sp,112
    80003b74:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b76:	8a5e                	mv	s4,s7
    80003b78:	bfc9                	j	80003b4a <writei+0xe2>
    return -1;
    80003b7a:	557d                	li	a0,-1
}
    80003b7c:	8082                	ret
    return -1;
    80003b7e:	557d                	li	a0,-1
    80003b80:	bfe1                	j	80003b58 <writei+0xf0>
    return -1;
    80003b82:	557d                	li	a0,-1
    80003b84:	bfd1                	j	80003b58 <writei+0xf0>

0000000080003b86 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b86:	1141                	addi	sp,sp,-16
    80003b88:	e406                	sd	ra,8(sp)
    80003b8a:	e022                	sd	s0,0(sp)
    80003b8c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b8e:	4639                	li	a2,14
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	20c080e7          	jalr	524(ra) # 80000d9c <strncmp>
}
    80003b98:	60a2                	ld	ra,8(sp)
    80003b9a:	6402                	ld	s0,0(sp)
    80003b9c:	0141                	addi	sp,sp,16
    80003b9e:	8082                	ret

0000000080003ba0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ba0:	7139                	addi	sp,sp,-64
    80003ba2:	fc06                	sd	ra,56(sp)
    80003ba4:	f822                	sd	s0,48(sp)
    80003ba6:	f426                	sd	s1,40(sp)
    80003ba8:	f04a                	sd	s2,32(sp)
    80003baa:	ec4e                	sd	s3,24(sp)
    80003bac:	e852                	sd	s4,16(sp)
    80003bae:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bb0:	04451703          	lh	a4,68(a0)
    80003bb4:	4785                	li	a5,1
    80003bb6:	00f71a63          	bne	a4,a5,80003bca <dirlookup+0x2a>
    80003bba:	892a                	mv	s2,a0
    80003bbc:	89ae                	mv	s3,a1
    80003bbe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc0:	457c                	lw	a5,76(a0)
    80003bc2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bc4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc6:	e79d                	bnez	a5,80003bf4 <dirlookup+0x54>
    80003bc8:	a8a5                	j	80003c40 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bca:	00005517          	auipc	a0,0x5
    80003bce:	aa650513          	addi	a0,a0,-1370 # 80008670 <syscalls+0x1a8>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	966080e7          	jalr	-1690(ra) # 80000538 <panic>
      panic("dirlookup read");
    80003bda:	00005517          	auipc	a0,0x5
    80003bde:	aae50513          	addi	a0,a0,-1362 # 80008688 <syscalls+0x1c0>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	956080e7          	jalr	-1706(ra) # 80000538 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bea:	24c1                	addiw	s1,s1,16
    80003bec:	04c92783          	lw	a5,76(s2)
    80003bf0:	04f4f763          	bgeu	s1,a5,80003c3e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bf4:	4741                	li	a4,16
    80003bf6:	86a6                	mv	a3,s1
    80003bf8:	fc040613          	addi	a2,s0,-64
    80003bfc:	4581                	li	a1,0
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	d70080e7          	jalr	-656(ra) # 80003970 <readi>
    80003c08:	47c1                	li	a5,16
    80003c0a:	fcf518e3          	bne	a0,a5,80003bda <dirlookup+0x3a>
    if(de.inum == 0)
    80003c0e:	fc045783          	lhu	a5,-64(s0)
    80003c12:	dfe1                	beqz	a5,80003bea <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c14:	fc240593          	addi	a1,s0,-62
    80003c18:	854e                	mv	a0,s3
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	f6c080e7          	jalr	-148(ra) # 80003b86 <namecmp>
    80003c22:	f561                	bnez	a0,80003bea <dirlookup+0x4a>
      if(poff)
    80003c24:	000a0463          	beqz	s4,80003c2c <dirlookup+0x8c>
        *poff = off;
    80003c28:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c2c:	fc045583          	lhu	a1,-64(s0)
    80003c30:	00092503          	lw	a0,0(s2)
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	754080e7          	jalr	1876(ra) # 80003388 <iget>
    80003c3c:	a011                	j	80003c40 <dirlookup+0xa0>
  return 0;
    80003c3e:	4501                	li	a0,0
}
    80003c40:	70e2                	ld	ra,56(sp)
    80003c42:	7442                	ld	s0,48(sp)
    80003c44:	74a2                	ld	s1,40(sp)
    80003c46:	7902                	ld	s2,32(sp)
    80003c48:	69e2                	ld	s3,24(sp)
    80003c4a:	6a42                	ld	s4,16(sp)
    80003c4c:	6121                	addi	sp,sp,64
    80003c4e:	8082                	ret

0000000080003c50 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c50:	711d                	addi	sp,sp,-96
    80003c52:	ec86                	sd	ra,88(sp)
    80003c54:	e8a2                	sd	s0,80(sp)
    80003c56:	e4a6                	sd	s1,72(sp)
    80003c58:	e0ca                	sd	s2,64(sp)
    80003c5a:	fc4e                	sd	s3,56(sp)
    80003c5c:	f852                	sd	s4,48(sp)
    80003c5e:	f456                	sd	s5,40(sp)
    80003c60:	f05a                	sd	s6,32(sp)
    80003c62:	ec5e                	sd	s7,24(sp)
    80003c64:	e862                	sd	s8,16(sp)
    80003c66:	e466                	sd	s9,8(sp)
    80003c68:	1080                	addi	s0,sp,96
    80003c6a:	84aa                	mv	s1,a0
    80003c6c:	8aae                	mv	s5,a1
    80003c6e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c70:	00054703          	lbu	a4,0(a0)
    80003c74:	02f00793          	li	a5,47
    80003c78:	02f70363          	beq	a4,a5,80003c9e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c7c:	ffffe097          	auipc	ra,0xffffe
    80003c80:	d1a080e7          	jalr	-742(ra) # 80001996 <myproc>
    80003c84:	15053503          	ld	a0,336(a0)
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	9f6080e7          	jalr	-1546(ra) # 8000367e <idup>
    80003c90:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c92:	02f00913          	li	s2,47
  len = path - s;
    80003c96:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c98:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c9a:	4b85                	li	s7,1
    80003c9c:	a865                	j	80003d54 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c9e:	4585                	li	a1,1
    80003ca0:	4505                	li	a0,1
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	6e6080e7          	jalr	1766(ra) # 80003388 <iget>
    80003caa:	89aa                	mv	s3,a0
    80003cac:	b7dd                	j	80003c92 <namex+0x42>
      iunlockput(ip);
    80003cae:	854e                	mv	a0,s3
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	c6e080e7          	jalr	-914(ra) # 8000391e <iunlockput>
      return 0;
    80003cb8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cba:	854e                	mv	a0,s3
    80003cbc:	60e6                	ld	ra,88(sp)
    80003cbe:	6446                	ld	s0,80(sp)
    80003cc0:	64a6                	ld	s1,72(sp)
    80003cc2:	6906                	ld	s2,64(sp)
    80003cc4:	79e2                	ld	s3,56(sp)
    80003cc6:	7a42                	ld	s4,48(sp)
    80003cc8:	7aa2                	ld	s5,40(sp)
    80003cca:	7b02                	ld	s6,32(sp)
    80003ccc:	6be2                	ld	s7,24(sp)
    80003cce:	6c42                	ld	s8,16(sp)
    80003cd0:	6ca2                	ld	s9,8(sp)
    80003cd2:	6125                	addi	sp,sp,96
    80003cd4:	8082                	ret
      iunlock(ip);
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	aa6080e7          	jalr	-1370(ra) # 8000377e <iunlock>
      return ip;
    80003ce0:	bfe9                	j	80003cba <namex+0x6a>
      iunlockput(ip);
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	c3a080e7          	jalr	-966(ra) # 8000391e <iunlockput>
      return 0;
    80003cec:	89e6                	mv	s3,s9
    80003cee:	b7f1                	j	80003cba <namex+0x6a>
  len = path - s;
    80003cf0:	40b48633          	sub	a2,s1,a1
    80003cf4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cf8:	099c5463          	bge	s8,s9,80003d80 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cfc:	4639                	li	a2,14
    80003cfe:	8552                	mv	a0,s4
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	028080e7          	jalr	40(ra) # 80000d28 <memmove>
  while(*path == '/')
    80003d08:	0004c783          	lbu	a5,0(s1)
    80003d0c:	01279763          	bne	a5,s2,80003d1a <namex+0xca>
    path++;
    80003d10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d12:	0004c783          	lbu	a5,0(s1)
    80003d16:	ff278de3          	beq	a5,s2,80003d10 <namex+0xc0>
    ilock(ip);
    80003d1a:	854e                	mv	a0,s3
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	9a0080e7          	jalr	-1632(ra) # 800036bc <ilock>
    if(ip->type != T_DIR){
    80003d24:	04499783          	lh	a5,68(s3)
    80003d28:	f97793e3          	bne	a5,s7,80003cae <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d2c:	000a8563          	beqz	s5,80003d36 <namex+0xe6>
    80003d30:	0004c783          	lbu	a5,0(s1)
    80003d34:	d3cd                	beqz	a5,80003cd6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d36:	865a                	mv	a2,s6
    80003d38:	85d2                	mv	a1,s4
    80003d3a:	854e                	mv	a0,s3
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	e64080e7          	jalr	-412(ra) # 80003ba0 <dirlookup>
    80003d44:	8caa                	mv	s9,a0
    80003d46:	dd51                	beqz	a0,80003ce2 <namex+0x92>
    iunlockput(ip);
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	bd4080e7          	jalr	-1068(ra) # 8000391e <iunlockput>
    ip = next;
    80003d52:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d54:	0004c783          	lbu	a5,0(s1)
    80003d58:	05279763          	bne	a5,s2,80003da6 <namex+0x156>
    path++;
    80003d5c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d5e:	0004c783          	lbu	a5,0(s1)
    80003d62:	ff278de3          	beq	a5,s2,80003d5c <namex+0x10c>
  if(*path == 0)
    80003d66:	c79d                	beqz	a5,80003d94 <namex+0x144>
    path++;
    80003d68:	85a6                	mv	a1,s1
  len = path - s;
    80003d6a:	8cda                	mv	s9,s6
    80003d6c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d6e:	01278963          	beq	a5,s2,80003d80 <namex+0x130>
    80003d72:	dfbd                	beqz	a5,80003cf0 <namex+0xa0>
    path++;
    80003d74:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	ff279ce3          	bne	a5,s2,80003d72 <namex+0x122>
    80003d7e:	bf8d                	j	80003cf0 <namex+0xa0>
    memmove(name, s, len);
    80003d80:	2601                	sext.w	a2,a2
    80003d82:	8552                	mv	a0,s4
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	fa4080e7          	jalr	-92(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003d8c:	9cd2                	add	s9,s9,s4
    80003d8e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d92:	bf9d                	j	80003d08 <namex+0xb8>
  if(nameiparent){
    80003d94:	f20a83e3          	beqz	s5,80003cba <namex+0x6a>
    iput(ip);
    80003d98:	854e                	mv	a0,s3
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	adc080e7          	jalr	-1316(ra) # 80003876 <iput>
    return 0;
    80003da2:	4981                	li	s3,0
    80003da4:	bf19                	j	80003cba <namex+0x6a>
  if(*path == 0)
    80003da6:	d7fd                	beqz	a5,80003d94 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003da8:	0004c783          	lbu	a5,0(s1)
    80003dac:	85a6                	mv	a1,s1
    80003dae:	b7d1                	j	80003d72 <namex+0x122>

0000000080003db0 <dirlink>:
{
    80003db0:	7139                	addi	sp,sp,-64
    80003db2:	fc06                	sd	ra,56(sp)
    80003db4:	f822                	sd	s0,48(sp)
    80003db6:	f426                	sd	s1,40(sp)
    80003db8:	f04a                	sd	s2,32(sp)
    80003dba:	ec4e                	sd	s3,24(sp)
    80003dbc:	e852                	sd	s4,16(sp)
    80003dbe:	0080                	addi	s0,sp,64
    80003dc0:	892a                	mv	s2,a0
    80003dc2:	8a2e                	mv	s4,a1
    80003dc4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dc6:	4601                	li	a2,0
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	dd8080e7          	jalr	-552(ra) # 80003ba0 <dirlookup>
    80003dd0:	e93d                	bnez	a0,80003e46 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd2:	04c92483          	lw	s1,76(s2)
    80003dd6:	c49d                	beqz	s1,80003e04 <dirlink+0x54>
    80003dd8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dda:	4741                	li	a4,16
    80003ddc:	86a6                	mv	a3,s1
    80003dde:	fc040613          	addi	a2,s0,-64
    80003de2:	4581                	li	a1,0
    80003de4:	854a                	mv	a0,s2
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	b8a080e7          	jalr	-1142(ra) # 80003970 <readi>
    80003dee:	47c1                	li	a5,16
    80003df0:	06f51163          	bne	a0,a5,80003e52 <dirlink+0xa2>
    if(de.inum == 0)
    80003df4:	fc045783          	lhu	a5,-64(s0)
    80003df8:	c791                	beqz	a5,80003e04 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfa:	24c1                	addiw	s1,s1,16
    80003dfc:	04c92783          	lw	a5,76(s2)
    80003e00:	fcf4ede3          	bltu	s1,a5,80003dda <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e04:	4639                	li	a2,14
    80003e06:	85d2                	mv	a1,s4
    80003e08:	fc240513          	addi	a0,s0,-62
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	fcc080e7          	jalr	-52(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003e14:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e18:	4741                	li	a4,16
    80003e1a:	86a6                	mv	a3,s1
    80003e1c:	fc040613          	addi	a2,s0,-64
    80003e20:	4581                	li	a1,0
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	c44080e7          	jalr	-956(ra) # 80003a68 <writei>
    80003e2c:	872a                	mv	a4,a0
    80003e2e:	47c1                	li	a5,16
  return 0;
    80003e30:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e32:	02f71863          	bne	a4,a5,80003e62 <dirlink+0xb2>
}
    80003e36:	70e2                	ld	ra,56(sp)
    80003e38:	7442                	ld	s0,48(sp)
    80003e3a:	74a2                	ld	s1,40(sp)
    80003e3c:	7902                	ld	s2,32(sp)
    80003e3e:	69e2                	ld	s3,24(sp)
    80003e40:	6a42                	ld	s4,16(sp)
    80003e42:	6121                	addi	sp,sp,64
    80003e44:	8082                	ret
    iput(ip);
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	a30080e7          	jalr	-1488(ra) # 80003876 <iput>
    return -1;
    80003e4e:	557d                	li	a0,-1
    80003e50:	b7dd                	j	80003e36 <dirlink+0x86>
      panic("dirlink read");
    80003e52:	00005517          	auipc	a0,0x5
    80003e56:	84650513          	addi	a0,a0,-1978 # 80008698 <syscalls+0x1d0>
    80003e5a:	ffffc097          	auipc	ra,0xffffc
    80003e5e:	6de080e7          	jalr	1758(ra) # 80000538 <panic>
    panic("dirlink");
    80003e62:	00005517          	auipc	a0,0x5
    80003e66:	94650513          	addi	a0,a0,-1722 # 800087a8 <syscalls+0x2e0>
    80003e6a:	ffffc097          	auipc	ra,0xffffc
    80003e6e:	6ce080e7          	jalr	1742(ra) # 80000538 <panic>

0000000080003e72 <namei>:

struct inode*
namei(char *path)
{
    80003e72:	1101                	addi	sp,sp,-32
    80003e74:	ec06                	sd	ra,24(sp)
    80003e76:	e822                	sd	s0,16(sp)
    80003e78:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e7a:	fe040613          	addi	a2,s0,-32
    80003e7e:	4581                	li	a1,0
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	dd0080e7          	jalr	-560(ra) # 80003c50 <namex>
}
    80003e88:	60e2                	ld	ra,24(sp)
    80003e8a:	6442                	ld	s0,16(sp)
    80003e8c:	6105                	addi	sp,sp,32
    80003e8e:	8082                	ret

0000000080003e90 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e90:	1141                	addi	sp,sp,-16
    80003e92:	e406                	sd	ra,8(sp)
    80003e94:	e022                	sd	s0,0(sp)
    80003e96:	0800                	addi	s0,sp,16
    80003e98:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e9a:	4585                	li	a1,1
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	db4080e7          	jalr	-588(ra) # 80003c50 <namex>
}
    80003ea4:	60a2                	ld	ra,8(sp)
    80003ea6:	6402                	ld	s0,0(sp)
    80003ea8:	0141                	addi	sp,sp,16
    80003eaa:	8082                	ret

0000000080003eac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	e04a                	sd	s2,0(sp)
    80003eb6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003eb8:	0001d917          	auipc	s2,0x1d
    80003ebc:	3b890913          	addi	s2,s2,952 # 80021270 <log>
    80003ec0:	01892583          	lw	a1,24(s2)
    80003ec4:	02892503          	lw	a0,40(s2)
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	ff2080e7          	jalr	-14(ra) # 80002eba <bread>
    80003ed0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ed2:	02c92683          	lw	a3,44(s2)
    80003ed6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ed8:	02d05763          	blez	a3,80003f06 <write_head+0x5a>
    80003edc:	0001d797          	auipc	a5,0x1d
    80003ee0:	3c478793          	addi	a5,a5,964 # 800212a0 <log+0x30>
    80003ee4:	05c50713          	addi	a4,a0,92
    80003ee8:	36fd                	addiw	a3,a3,-1
    80003eea:	1682                	slli	a3,a3,0x20
    80003eec:	9281                	srli	a3,a3,0x20
    80003eee:	068a                	slli	a3,a3,0x2
    80003ef0:	0001d617          	auipc	a2,0x1d
    80003ef4:	3b460613          	addi	a2,a2,948 # 800212a4 <log+0x34>
    80003ef8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003efa:	4390                	lw	a2,0(a5)
    80003efc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003efe:	0791                	addi	a5,a5,4
    80003f00:	0711                	addi	a4,a4,4
    80003f02:	fed79ce3          	bne	a5,a3,80003efa <write_head+0x4e>
  }
  bwrite(buf);
    80003f06:	8526                	mv	a0,s1
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	0a4080e7          	jalr	164(ra) # 80002fac <bwrite>
  brelse(buf);
    80003f10:	8526                	mv	a0,s1
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	0d8080e7          	jalr	216(ra) # 80002fea <brelse>
}
    80003f1a:	60e2                	ld	ra,24(sp)
    80003f1c:	6442                	ld	s0,16(sp)
    80003f1e:	64a2                	ld	s1,8(sp)
    80003f20:	6902                	ld	s2,0(sp)
    80003f22:	6105                	addi	sp,sp,32
    80003f24:	8082                	ret

0000000080003f26 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f26:	0001d797          	auipc	a5,0x1d
    80003f2a:	3767a783          	lw	a5,886(a5) # 8002129c <log+0x2c>
    80003f2e:	0af05d63          	blez	a5,80003fe8 <install_trans+0xc2>
{
    80003f32:	7139                	addi	sp,sp,-64
    80003f34:	fc06                	sd	ra,56(sp)
    80003f36:	f822                	sd	s0,48(sp)
    80003f38:	f426                	sd	s1,40(sp)
    80003f3a:	f04a                	sd	s2,32(sp)
    80003f3c:	ec4e                	sd	s3,24(sp)
    80003f3e:	e852                	sd	s4,16(sp)
    80003f40:	e456                	sd	s5,8(sp)
    80003f42:	e05a                	sd	s6,0(sp)
    80003f44:	0080                	addi	s0,sp,64
    80003f46:	8b2a                	mv	s6,a0
    80003f48:	0001da97          	auipc	s5,0x1d
    80003f4c:	358a8a93          	addi	s5,s5,856 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f50:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f52:	0001d997          	auipc	s3,0x1d
    80003f56:	31e98993          	addi	s3,s3,798 # 80021270 <log>
    80003f5a:	a00d                	j	80003f7c <install_trans+0x56>
    brelse(lbuf);
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	08c080e7          	jalr	140(ra) # 80002fea <brelse>
    brelse(dbuf);
    80003f66:	8526                	mv	a0,s1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	082080e7          	jalr	130(ra) # 80002fea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f70:	2a05                	addiw	s4,s4,1
    80003f72:	0a91                	addi	s5,s5,4
    80003f74:	02c9a783          	lw	a5,44(s3)
    80003f78:	04fa5e63          	bge	s4,a5,80003fd4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f7c:	0189a583          	lw	a1,24(s3)
    80003f80:	014585bb          	addw	a1,a1,s4
    80003f84:	2585                	addiw	a1,a1,1
    80003f86:	0289a503          	lw	a0,40(s3)
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	f30080e7          	jalr	-208(ra) # 80002eba <bread>
    80003f92:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f94:	000aa583          	lw	a1,0(s5)
    80003f98:	0289a503          	lw	a0,40(s3)
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	f1e080e7          	jalr	-226(ra) # 80002eba <bread>
    80003fa4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fa6:	40000613          	li	a2,1024
    80003faa:	05890593          	addi	a1,s2,88
    80003fae:	05850513          	addi	a0,a0,88
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	d76080e7          	jalr	-650(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fba:	8526                	mv	a0,s1
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	ff0080e7          	jalr	-16(ra) # 80002fac <bwrite>
    if(recovering == 0)
    80003fc4:	f80b1ce3          	bnez	s6,80003f5c <install_trans+0x36>
      bunpin(dbuf);
    80003fc8:	8526                	mv	a0,s1
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	0fa080e7          	jalr	250(ra) # 800030c4 <bunpin>
    80003fd2:	b769                	j	80003f5c <install_trans+0x36>
}
    80003fd4:	70e2                	ld	ra,56(sp)
    80003fd6:	7442                	ld	s0,48(sp)
    80003fd8:	74a2                	ld	s1,40(sp)
    80003fda:	7902                	ld	s2,32(sp)
    80003fdc:	69e2                	ld	s3,24(sp)
    80003fde:	6a42                	ld	s4,16(sp)
    80003fe0:	6aa2                	ld	s5,8(sp)
    80003fe2:	6b02                	ld	s6,0(sp)
    80003fe4:	6121                	addi	sp,sp,64
    80003fe6:	8082                	ret
    80003fe8:	8082                	ret

0000000080003fea <initlog>:
{
    80003fea:	7179                	addi	sp,sp,-48
    80003fec:	f406                	sd	ra,40(sp)
    80003fee:	f022                	sd	s0,32(sp)
    80003ff0:	ec26                	sd	s1,24(sp)
    80003ff2:	e84a                	sd	s2,16(sp)
    80003ff4:	e44e                	sd	s3,8(sp)
    80003ff6:	1800                	addi	s0,sp,48
    80003ff8:	892a                	mv	s2,a0
    80003ffa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ffc:	0001d497          	auipc	s1,0x1d
    80004000:	27448493          	addi	s1,s1,628 # 80021270 <log>
    80004004:	00004597          	auipc	a1,0x4
    80004008:	6a458593          	addi	a1,a1,1700 # 800086a8 <syscalls+0x1e0>
    8000400c:	8526                	mv	a0,s1
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	b32080e7          	jalr	-1230(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004016:	0149a583          	lw	a1,20(s3)
    8000401a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000401c:	0109a783          	lw	a5,16(s3)
    80004020:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004022:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004026:	854a                	mv	a0,s2
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	e92080e7          	jalr	-366(ra) # 80002eba <bread>
  log.lh.n = lh->n;
    80004030:	4d34                	lw	a3,88(a0)
    80004032:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004034:	02d05563          	blez	a3,8000405e <initlog+0x74>
    80004038:	05c50793          	addi	a5,a0,92
    8000403c:	0001d717          	auipc	a4,0x1d
    80004040:	26470713          	addi	a4,a4,612 # 800212a0 <log+0x30>
    80004044:	36fd                	addiw	a3,a3,-1
    80004046:	1682                	slli	a3,a3,0x20
    80004048:	9281                	srli	a3,a3,0x20
    8000404a:	068a                	slli	a3,a3,0x2
    8000404c:	06050613          	addi	a2,a0,96
    80004050:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004052:	4390                	lw	a2,0(a5)
    80004054:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004056:	0791                	addi	a5,a5,4
    80004058:	0711                	addi	a4,a4,4
    8000405a:	fed79ce3          	bne	a5,a3,80004052 <initlog+0x68>
  brelse(buf);
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	f8c080e7          	jalr	-116(ra) # 80002fea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004066:	4505                	li	a0,1
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	ebe080e7          	jalr	-322(ra) # 80003f26 <install_trans>
  log.lh.n = 0;
    80004070:	0001d797          	auipc	a5,0x1d
    80004074:	2207a623          	sw	zero,556(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	e34080e7          	jalr	-460(ra) # 80003eac <write_head>
}
    80004080:	70a2                	ld	ra,40(sp)
    80004082:	7402                	ld	s0,32(sp)
    80004084:	64e2                	ld	s1,24(sp)
    80004086:	6942                	ld	s2,16(sp)
    80004088:	69a2                	ld	s3,8(sp)
    8000408a:	6145                	addi	sp,sp,48
    8000408c:	8082                	ret

000000008000408e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000408e:	1101                	addi	sp,sp,-32
    80004090:	ec06                	sd	ra,24(sp)
    80004092:	e822                	sd	s0,16(sp)
    80004094:	e426                	sd	s1,8(sp)
    80004096:	e04a                	sd	s2,0(sp)
    80004098:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000409a:	0001d517          	auipc	a0,0x1d
    8000409e:	1d650513          	addi	a0,a0,470 # 80021270 <log>
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	b2e080e7          	jalr	-1234(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800040aa:	0001d497          	auipc	s1,0x1d
    800040ae:	1c648493          	addi	s1,s1,454 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040b2:	4979                	li	s2,30
    800040b4:	a039                	j	800040c2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040b6:	85a6                	mv	a1,s1
    800040b8:	8526                	mv	a0,s1
    800040ba:	ffffe097          	auipc	ra,0xffffe
    800040be:	f9c080e7          	jalr	-100(ra) # 80002056 <sleep>
    if(log.committing){
    800040c2:	50dc                	lw	a5,36(s1)
    800040c4:	fbed                	bnez	a5,800040b6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040c6:	509c                	lw	a5,32(s1)
    800040c8:	0017871b          	addiw	a4,a5,1
    800040cc:	0007069b          	sext.w	a3,a4
    800040d0:	0027179b          	slliw	a5,a4,0x2
    800040d4:	9fb9                	addw	a5,a5,a4
    800040d6:	0017979b          	slliw	a5,a5,0x1
    800040da:	54d8                	lw	a4,44(s1)
    800040dc:	9fb9                	addw	a5,a5,a4
    800040de:	00f95963          	bge	s2,a5,800040f0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040e2:	85a6                	mv	a1,s1
    800040e4:	8526                	mv	a0,s1
    800040e6:	ffffe097          	auipc	ra,0xffffe
    800040ea:	f70080e7          	jalr	-144(ra) # 80002056 <sleep>
    800040ee:	bfd1                	j	800040c2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040f0:	0001d517          	auipc	a0,0x1d
    800040f4:	18050513          	addi	a0,a0,384 # 80021270 <log>
    800040f8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	b8a080e7          	jalr	-1142(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004102:	60e2                	ld	ra,24(sp)
    80004104:	6442                	ld	s0,16(sp)
    80004106:	64a2                	ld	s1,8(sp)
    80004108:	6902                	ld	s2,0(sp)
    8000410a:	6105                	addi	sp,sp,32
    8000410c:	8082                	ret

000000008000410e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000410e:	7139                	addi	sp,sp,-64
    80004110:	fc06                	sd	ra,56(sp)
    80004112:	f822                	sd	s0,48(sp)
    80004114:	f426                	sd	s1,40(sp)
    80004116:	f04a                	sd	s2,32(sp)
    80004118:	ec4e                	sd	s3,24(sp)
    8000411a:	e852                	sd	s4,16(sp)
    8000411c:	e456                	sd	s5,8(sp)
    8000411e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004120:	0001d497          	auipc	s1,0x1d
    80004124:	15048493          	addi	s1,s1,336 # 80021270 <log>
    80004128:	8526                	mv	a0,s1
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	aa6080e7          	jalr	-1370(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004132:	509c                	lw	a5,32(s1)
    80004134:	37fd                	addiw	a5,a5,-1
    80004136:	0007891b          	sext.w	s2,a5
    8000413a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000413c:	50dc                	lw	a5,36(s1)
    8000413e:	e7b9                	bnez	a5,8000418c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004140:	04091e63          	bnez	s2,8000419c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004144:	0001d497          	auipc	s1,0x1d
    80004148:	12c48493          	addi	s1,s1,300 # 80021270 <log>
    8000414c:	4785                	li	a5,1
    8000414e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004150:	8526                	mv	a0,s1
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	b32080e7          	jalr	-1230(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000415a:	54dc                	lw	a5,44(s1)
    8000415c:	06f04763          	bgtz	a5,800041ca <end_op+0xbc>
    acquire(&log.lock);
    80004160:	0001d497          	auipc	s1,0x1d
    80004164:	11048493          	addi	s1,s1,272 # 80021270 <log>
    80004168:	8526                	mv	a0,s1
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	a66080e7          	jalr	-1434(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004172:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004176:	8526                	mv	a0,s1
    80004178:	ffffe097          	auipc	ra,0xffffe
    8000417c:	06a080e7          	jalr	106(ra) # 800021e2 <wakeup>
    release(&log.lock);
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	b02080e7          	jalr	-1278(ra) # 80000c84 <release>
}
    8000418a:	a03d                	j	800041b8 <end_op+0xaa>
    panic("log.committing");
    8000418c:	00004517          	auipc	a0,0x4
    80004190:	52450513          	addi	a0,a0,1316 # 800086b0 <syscalls+0x1e8>
    80004194:	ffffc097          	auipc	ra,0xffffc
    80004198:	3a4080e7          	jalr	932(ra) # 80000538 <panic>
    wakeup(&log);
    8000419c:	0001d497          	auipc	s1,0x1d
    800041a0:	0d448493          	addi	s1,s1,212 # 80021270 <log>
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffe097          	auipc	ra,0xffffe
    800041aa:	03c080e7          	jalr	60(ra) # 800021e2 <wakeup>
  release(&log.lock);
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	ad4080e7          	jalr	-1324(ra) # 80000c84 <release>
}
    800041b8:	70e2                	ld	ra,56(sp)
    800041ba:	7442                	ld	s0,48(sp)
    800041bc:	74a2                	ld	s1,40(sp)
    800041be:	7902                	ld	s2,32(sp)
    800041c0:	69e2                	ld	s3,24(sp)
    800041c2:	6a42                	ld	s4,16(sp)
    800041c4:	6aa2                	ld	s5,8(sp)
    800041c6:	6121                	addi	sp,sp,64
    800041c8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ca:	0001da97          	auipc	s5,0x1d
    800041ce:	0d6a8a93          	addi	s5,s5,214 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041d2:	0001da17          	auipc	s4,0x1d
    800041d6:	09ea0a13          	addi	s4,s4,158 # 80021270 <log>
    800041da:	018a2583          	lw	a1,24(s4)
    800041de:	012585bb          	addw	a1,a1,s2
    800041e2:	2585                	addiw	a1,a1,1
    800041e4:	028a2503          	lw	a0,40(s4)
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	cd2080e7          	jalr	-814(ra) # 80002eba <bread>
    800041f0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041f2:	000aa583          	lw	a1,0(s5)
    800041f6:	028a2503          	lw	a0,40(s4)
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	cc0080e7          	jalr	-832(ra) # 80002eba <bread>
    80004202:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004204:	40000613          	li	a2,1024
    80004208:	05850593          	addi	a1,a0,88
    8000420c:	05848513          	addi	a0,s1,88
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	b18080e7          	jalr	-1256(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    80004218:	8526                	mv	a0,s1
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	d92080e7          	jalr	-622(ra) # 80002fac <bwrite>
    brelse(from);
    80004222:	854e                	mv	a0,s3
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	dc6080e7          	jalr	-570(ra) # 80002fea <brelse>
    brelse(to);
    8000422c:	8526                	mv	a0,s1
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	dbc080e7          	jalr	-580(ra) # 80002fea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004236:	2905                	addiw	s2,s2,1
    80004238:	0a91                	addi	s5,s5,4
    8000423a:	02ca2783          	lw	a5,44(s4)
    8000423e:	f8f94ee3          	blt	s2,a5,800041da <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004242:	00000097          	auipc	ra,0x0
    80004246:	c6a080e7          	jalr	-918(ra) # 80003eac <write_head>
    install_trans(0); // Now install writes to home locations
    8000424a:	4501                	li	a0,0
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	cda080e7          	jalr	-806(ra) # 80003f26 <install_trans>
    log.lh.n = 0;
    80004254:	0001d797          	auipc	a5,0x1d
    80004258:	0407a423          	sw	zero,72(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	c50080e7          	jalr	-944(ra) # 80003eac <write_head>
    80004264:	bdf5                	j	80004160 <end_op+0x52>

0000000080004266 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004266:	1101                	addi	sp,sp,-32
    80004268:	ec06                	sd	ra,24(sp)
    8000426a:	e822                	sd	s0,16(sp)
    8000426c:	e426                	sd	s1,8(sp)
    8000426e:	e04a                	sd	s2,0(sp)
    80004270:	1000                	addi	s0,sp,32
    80004272:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004274:	0001d917          	auipc	s2,0x1d
    80004278:	ffc90913          	addi	s2,s2,-4 # 80021270 <log>
    8000427c:	854a                	mv	a0,s2
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	952080e7          	jalr	-1710(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004286:	02c92603          	lw	a2,44(s2)
    8000428a:	47f5                	li	a5,29
    8000428c:	06c7c563          	blt	a5,a2,800042f6 <log_write+0x90>
    80004290:	0001d797          	auipc	a5,0x1d
    80004294:	ffc7a783          	lw	a5,-4(a5) # 8002128c <log+0x1c>
    80004298:	37fd                	addiw	a5,a5,-1
    8000429a:	04f65e63          	bge	a2,a5,800042f6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000429e:	0001d797          	auipc	a5,0x1d
    800042a2:	ff27a783          	lw	a5,-14(a5) # 80021290 <log+0x20>
    800042a6:	06f05063          	blez	a5,80004306 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042aa:	4781                	li	a5,0
    800042ac:	06c05563          	blez	a2,80004316 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042b0:	44cc                	lw	a1,12(s1)
    800042b2:	0001d717          	auipc	a4,0x1d
    800042b6:	fee70713          	addi	a4,a4,-18 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042ba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042bc:	4314                	lw	a3,0(a4)
    800042be:	04b68c63          	beq	a3,a1,80004316 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042c2:	2785                	addiw	a5,a5,1
    800042c4:	0711                	addi	a4,a4,4
    800042c6:	fef61be3          	bne	a2,a5,800042bc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ca:	0621                	addi	a2,a2,8
    800042cc:	060a                	slli	a2,a2,0x2
    800042ce:	0001d797          	auipc	a5,0x1d
    800042d2:	fa278793          	addi	a5,a5,-94 # 80021270 <log>
    800042d6:	963e                	add	a2,a2,a5
    800042d8:	44dc                	lw	a5,12(s1)
    800042da:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042dc:	8526                	mv	a0,s1
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	daa080e7          	jalr	-598(ra) # 80003088 <bpin>
    log.lh.n++;
    800042e6:	0001d717          	auipc	a4,0x1d
    800042ea:	f8a70713          	addi	a4,a4,-118 # 80021270 <log>
    800042ee:	575c                	lw	a5,44(a4)
    800042f0:	2785                	addiw	a5,a5,1
    800042f2:	d75c                	sw	a5,44(a4)
    800042f4:	a835                	j	80004330 <log_write+0xca>
    panic("too big a transaction");
    800042f6:	00004517          	auipc	a0,0x4
    800042fa:	3ca50513          	addi	a0,a0,970 # 800086c0 <syscalls+0x1f8>
    800042fe:	ffffc097          	auipc	ra,0xffffc
    80004302:	23a080e7          	jalr	570(ra) # 80000538 <panic>
    panic("log_write outside of trans");
    80004306:	00004517          	auipc	a0,0x4
    8000430a:	3d250513          	addi	a0,a0,978 # 800086d8 <syscalls+0x210>
    8000430e:	ffffc097          	auipc	ra,0xffffc
    80004312:	22a080e7          	jalr	554(ra) # 80000538 <panic>
  log.lh.block[i] = b->blockno;
    80004316:	00878713          	addi	a4,a5,8
    8000431a:	00271693          	slli	a3,a4,0x2
    8000431e:	0001d717          	auipc	a4,0x1d
    80004322:	f5270713          	addi	a4,a4,-174 # 80021270 <log>
    80004326:	9736                	add	a4,a4,a3
    80004328:	44d4                	lw	a3,12(s1)
    8000432a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000432c:	faf608e3          	beq	a2,a5,800042dc <log_write+0x76>
  }
  release(&log.lock);
    80004330:	0001d517          	auipc	a0,0x1d
    80004334:	f4050513          	addi	a0,a0,-192 # 80021270 <log>
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	94c080e7          	jalr	-1716(ra) # 80000c84 <release>
}
    80004340:	60e2                	ld	ra,24(sp)
    80004342:	6442                	ld	s0,16(sp)
    80004344:	64a2                	ld	s1,8(sp)
    80004346:	6902                	ld	s2,0(sp)
    80004348:	6105                	addi	sp,sp,32
    8000434a:	8082                	ret

000000008000434c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	addi	s0,sp,32
    80004358:	84aa                	mv	s1,a0
    8000435a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000435c:	00004597          	auipc	a1,0x4
    80004360:	39c58593          	addi	a1,a1,924 # 800086f8 <syscalls+0x230>
    80004364:	0521                	addi	a0,a0,8
    80004366:	ffffc097          	auipc	ra,0xffffc
    8000436a:	7da080e7          	jalr	2010(ra) # 80000b40 <initlock>
  lk->name = name;
    8000436e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004372:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004376:	0204a423          	sw	zero,40(s1)
}
    8000437a:	60e2                	ld	ra,24(sp)
    8000437c:	6442                	ld	s0,16(sp)
    8000437e:	64a2                	ld	s1,8(sp)
    80004380:	6902                	ld	s2,0(sp)
    80004382:	6105                	addi	sp,sp,32
    80004384:	8082                	ret

0000000080004386 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004386:	1101                	addi	sp,sp,-32
    80004388:	ec06                	sd	ra,24(sp)
    8000438a:	e822                	sd	s0,16(sp)
    8000438c:	e426                	sd	s1,8(sp)
    8000438e:	e04a                	sd	s2,0(sp)
    80004390:	1000                	addi	s0,sp,32
    80004392:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004394:	00850913          	addi	s2,a0,8
    80004398:	854a                	mv	a0,s2
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	836080e7          	jalr	-1994(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800043a2:	409c                	lw	a5,0(s1)
    800043a4:	cb89                	beqz	a5,800043b6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043a6:	85ca                	mv	a1,s2
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	cac080e7          	jalr	-852(ra) # 80002056 <sleep>
  while (lk->locked) {
    800043b2:	409c                	lw	a5,0(s1)
    800043b4:	fbed                	bnez	a5,800043a6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043b6:	4785                	li	a5,1
    800043b8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043ba:	ffffd097          	auipc	ra,0xffffd
    800043be:	5dc080e7          	jalr	1500(ra) # 80001996 <myproc>
    800043c2:	591c                	lw	a5,48(a0)
    800043c4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043c6:	854a                	mv	a0,s2
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	8bc080e7          	jalr	-1860(ra) # 80000c84 <release>
}
    800043d0:	60e2                	ld	ra,24(sp)
    800043d2:	6442                	ld	s0,16(sp)
    800043d4:	64a2                	ld	s1,8(sp)
    800043d6:	6902                	ld	s2,0(sp)
    800043d8:	6105                	addi	sp,sp,32
    800043da:	8082                	ret

00000000800043dc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043dc:	1101                	addi	sp,sp,-32
    800043de:	ec06                	sd	ra,24(sp)
    800043e0:	e822                	sd	s0,16(sp)
    800043e2:	e426                	sd	s1,8(sp)
    800043e4:	e04a                	sd	s2,0(sp)
    800043e6:	1000                	addi	s0,sp,32
    800043e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ea:	00850913          	addi	s2,a0,8
    800043ee:	854a                	mv	a0,s2
    800043f0:	ffffc097          	auipc	ra,0xffffc
    800043f4:	7e0080e7          	jalr	2016(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800043f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043fc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004400:	8526                	mv	a0,s1
    80004402:	ffffe097          	auipc	ra,0xffffe
    80004406:	de0080e7          	jalr	-544(ra) # 800021e2 <wakeup>
  release(&lk->lk);
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	878080e7          	jalr	-1928(ra) # 80000c84 <release>
}
    80004414:	60e2                	ld	ra,24(sp)
    80004416:	6442                	ld	s0,16(sp)
    80004418:	64a2                	ld	s1,8(sp)
    8000441a:	6902                	ld	s2,0(sp)
    8000441c:	6105                	addi	sp,sp,32
    8000441e:	8082                	ret

0000000080004420 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004420:	7179                	addi	sp,sp,-48
    80004422:	f406                	sd	ra,40(sp)
    80004424:	f022                	sd	s0,32(sp)
    80004426:	ec26                	sd	s1,24(sp)
    80004428:	e84a                	sd	s2,16(sp)
    8000442a:	e44e                	sd	s3,8(sp)
    8000442c:	1800                	addi	s0,sp,48
    8000442e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004430:	00850913          	addi	s2,a0,8
    80004434:	854a                	mv	a0,s2
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	79a080e7          	jalr	1946(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000443e:	409c                	lw	a5,0(s1)
    80004440:	ef99                	bnez	a5,8000445e <holdingsleep+0x3e>
    80004442:	4481                	li	s1,0
  release(&lk->lk);
    80004444:	854a                	mv	a0,s2
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	83e080e7          	jalr	-1986(ra) # 80000c84 <release>
  return r;
}
    8000444e:	8526                	mv	a0,s1
    80004450:	70a2                	ld	ra,40(sp)
    80004452:	7402                	ld	s0,32(sp)
    80004454:	64e2                	ld	s1,24(sp)
    80004456:	6942                	ld	s2,16(sp)
    80004458:	69a2                	ld	s3,8(sp)
    8000445a:	6145                	addi	sp,sp,48
    8000445c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000445e:	0284a983          	lw	s3,40(s1)
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	534080e7          	jalr	1332(ra) # 80001996 <myproc>
    8000446a:	5904                	lw	s1,48(a0)
    8000446c:	413484b3          	sub	s1,s1,s3
    80004470:	0014b493          	seqz	s1,s1
    80004474:	bfc1                	j	80004444 <holdingsleep+0x24>

0000000080004476 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004476:	1141                	addi	sp,sp,-16
    80004478:	e406                	sd	ra,8(sp)
    8000447a:	e022                	sd	s0,0(sp)
    8000447c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000447e:	00004597          	auipc	a1,0x4
    80004482:	28a58593          	addi	a1,a1,650 # 80008708 <syscalls+0x240>
    80004486:	0001d517          	auipc	a0,0x1d
    8000448a:	f3250513          	addi	a0,a0,-206 # 800213b8 <ftable>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	6b2080e7          	jalr	1714(ra) # 80000b40 <initlock>
}
    80004496:	60a2                	ld	ra,8(sp)
    80004498:	6402                	ld	s0,0(sp)
    8000449a:	0141                	addi	sp,sp,16
    8000449c:	8082                	ret

000000008000449e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000449e:	1101                	addi	sp,sp,-32
    800044a0:	ec06                	sd	ra,24(sp)
    800044a2:	e822                	sd	s0,16(sp)
    800044a4:	e426                	sd	s1,8(sp)
    800044a6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044a8:	0001d517          	auipc	a0,0x1d
    800044ac:	f1050513          	addi	a0,a0,-240 # 800213b8 <ftable>
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	720080e7          	jalr	1824(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044b8:	0001d497          	auipc	s1,0x1d
    800044bc:	f1848493          	addi	s1,s1,-232 # 800213d0 <ftable+0x18>
    800044c0:	0001e717          	auipc	a4,0x1e
    800044c4:	eb070713          	addi	a4,a4,-336 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800044c8:	40dc                	lw	a5,4(s1)
    800044ca:	cf99                	beqz	a5,800044e8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044cc:	02848493          	addi	s1,s1,40
    800044d0:	fee49ce3          	bne	s1,a4,800044c8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044d4:	0001d517          	auipc	a0,0x1d
    800044d8:	ee450513          	addi	a0,a0,-284 # 800213b8 <ftable>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7a8080e7          	jalr	1960(ra) # 80000c84 <release>
  return 0;
    800044e4:	4481                	li	s1,0
    800044e6:	a819                	j	800044fc <filealloc+0x5e>
      f->ref = 1;
    800044e8:	4785                	li	a5,1
    800044ea:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044ec:	0001d517          	auipc	a0,0x1d
    800044f0:	ecc50513          	addi	a0,a0,-308 # 800213b8 <ftable>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	790080e7          	jalr	1936(ra) # 80000c84 <release>
}
    800044fc:	8526                	mv	a0,s1
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret

0000000080004508 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	1000                	addi	s0,sp,32
    80004512:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004514:	0001d517          	auipc	a0,0x1d
    80004518:	ea450513          	addi	a0,a0,-348 # 800213b8 <ftable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	6b4080e7          	jalr	1716(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004524:	40dc                	lw	a5,4(s1)
    80004526:	02f05263          	blez	a5,8000454a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000452a:	2785                	addiw	a5,a5,1
    8000452c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000452e:	0001d517          	auipc	a0,0x1d
    80004532:	e8a50513          	addi	a0,a0,-374 # 800213b8 <ftable>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	74e080e7          	jalr	1870(ra) # 80000c84 <release>
  return f;
}
    8000453e:	8526                	mv	a0,s1
    80004540:	60e2                	ld	ra,24(sp)
    80004542:	6442                	ld	s0,16(sp)
    80004544:	64a2                	ld	s1,8(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret
    panic("filedup");
    8000454a:	00004517          	auipc	a0,0x4
    8000454e:	1c650513          	addi	a0,a0,454 # 80008710 <syscalls+0x248>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	fe6080e7          	jalr	-26(ra) # 80000538 <panic>

000000008000455a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000455a:	7139                	addi	sp,sp,-64
    8000455c:	fc06                	sd	ra,56(sp)
    8000455e:	f822                	sd	s0,48(sp)
    80004560:	f426                	sd	s1,40(sp)
    80004562:	f04a                	sd	s2,32(sp)
    80004564:	ec4e                	sd	s3,24(sp)
    80004566:	e852                	sd	s4,16(sp)
    80004568:	e456                	sd	s5,8(sp)
    8000456a:	0080                	addi	s0,sp,64
    8000456c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000456e:	0001d517          	auipc	a0,0x1d
    80004572:	e4a50513          	addi	a0,a0,-438 # 800213b8 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	65a080e7          	jalr	1626(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000457e:	40dc                	lw	a5,4(s1)
    80004580:	06f05163          	blez	a5,800045e2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004584:	37fd                	addiw	a5,a5,-1
    80004586:	0007871b          	sext.w	a4,a5
    8000458a:	c0dc                	sw	a5,4(s1)
    8000458c:	06e04363          	bgtz	a4,800045f2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004590:	0004a903          	lw	s2,0(s1)
    80004594:	0094ca83          	lbu	s5,9(s1)
    80004598:	0104ba03          	ld	s4,16(s1)
    8000459c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045a0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045a4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045a8:	0001d517          	auipc	a0,0x1d
    800045ac:	e1050513          	addi	a0,a0,-496 # 800213b8 <ftable>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	6d4080e7          	jalr	1748(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800045b8:	4785                	li	a5,1
    800045ba:	04f90d63          	beq	s2,a5,80004614 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045be:	3979                	addiw	s2,s2,-2
    800045c0:	4785                	li	a5,1
    800045c2:	0527e063          	bltu	a5,s2,80004602 <fileclose+0xa8>
    begin_op();
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	ac8080e7          	jalr	-1336(ra) # 8000408e <begin_op>
    iput(ff.ip);
    800045ce:	854e                	mv	a0,s3
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	2a6080e7          	jalr	678(ra) # 80003876 <iput>
    end_op();
    800045d8:	00000097          	auipc	ra,0x0
    800045dc:	b36080e7          	jalr	-1226(ra) # 8000410e <end_op>
    800045e0:	a00d                	j	80004602 <fileclose+0xa8>
    panic("fileclose");
    800045e2:	00004517          	auipc	a0,0x4
    800045e6:	13650513          	addi	a0,a0,310 # 80008718 <syscalls+0x250>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	f4e080e7          	jalr	-178(ra) # 80000538 <panic>
    release(&ftable.lock);
    800045f2:	0001d517          	auipc	a0,0x1d
    800045f6:	dc650513          	addi	a0,a0,-570 # 800213b8 <ftable>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	68a080e7          	jalr	1674(ra) # 80000c84 <release>
  }
}
    80004602:	70e2                	ld	ra,56(sp)
    80004604:	7442                	ld	s0,48(sp)
    80004606:	74a2                	ld	s1,40(sp)
    80004608:	7902                	ld	s2,32(sp)
    8000460a:	69e2                	ld	s3,24(sp)
    8000460c:	6a42                	ld	s4,16(sp)
    8000460e:	6aa2                	ld	s5,8(sp)
    80004610:	6121                	addi	sp,sp,64
    80004612:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004614:	85d6                	mv	a1,s5
    80004616:	8552                	mv	a0,s4
    80004618:	00000097          	auipc	ra,0x0
    8000461c:	34c080e7          	jalr	844(ra) # 80004964 <pipeclose>
    80004620:	b7cd                	j	80004602 <fileclose+0xa8>

0000000080004622 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004622:	715d                	addi	sp,sp,-80
    80004624:	e486                	sd	ra,72(sp)
    80004626:	e0a2                	sd	s0,64(sp)
    80004628:	fc26                	sd	s1,56(sp)
    8000462a:	f84a                	sd	s2,48(sp)
    8000462c:	f44e                	sd	s3,40(sp)
    8000462e:	0880                	addi	s0,sp,80
    80004630:	84aa                	mv	s1,a0
    80004632:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004634:	ffffd097          	auipc	ra,0xffffd
    80004638:	362080e7          	jalr	866(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000463c:	409c                	lw	a5,0(s1)
    8000463e:	37f9                	addiw	a5,a5,-2
    80004640:	4705                	li	a4,1
    80004642:	04f76763          	bltu	a4,a5,80004690 <filestat+0x6e>
    80004646:	892a                	mv	s2,a0
    ilock(f->ip);
    80004648:	6c88                	ld	a0,24(s1)
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	072080e7          	jalr	114(ra) # 800036bc <ilock>
    stati(f->ip, &st);
    80004652:	fb840593          	addi	a1,s0,-72
    80004656:	6c88                	ld	a0,24(s1)
    80004658:	fffff097          	auipc	ra,0xfffff
    8000465c:	2ee080e7          	jalr	750(ra) # 80003946 <stati>
    iunlock(f->ip);
    80004660:	6c88                	ld	a0,24(s1)
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	11c080e7          	jalr	284(ra) # 8000377e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000466a:	46e1                	li	a3,24
    8000466c:	fb840613          	addi	a2,s0,-72
    80004670:	85ce                	mv	a1,s3
    80004672:	05093503          	ld	a0,80(s2)
    80004676:	ffffd097          	auipc	ra,0xffffd
    8000467a:	fe0080e7          	jalr	-32(ra) # 80001656 <copyout>
    8000467e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004682:	60a6                	ld	ra,72(sp)
    80004684:	6406                	ld	s0,64(sp)
    80004686:	74e2                	ld	s1,56(sp)
    80004688:	7942                	ld	s2,48(sp)
    8000468a:	79a2                	ld	s3,40(sp)
    8000468c:	6161                	addi	sp,sp,80
    8000468e:	8082                	ret
  return -1;
    80004690:	557d                	li	a0,-1
    80004692:	bfc5                	j	80004682 <filestat+0x60>

0000000080004694 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004694:	7179                	addi	sp,sp,-48
    80004696:	f406                	sd	ra,40(sp)
    80004698:	f022                	sd	s0,32(sp)
    8000469a:	ec26                	sd	s1,24(sp)
    8000469c:	e84a                	sd	s2,16(sp)
    8000469e:	e44e                	sd	s3,8(sp)
    800046a0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046a2:	00854783          	lbu	a5,8(a0)
    800046a6:	c3d5                	beqz	a5,8000474a <fileread+0xb6>
    800046a8:	84aa                	mv	s1,a0
    800046aa:	89ae                	mv	s3,a1
    800046ac:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ae:	411c                	lw	a5,0(a0)
    800046b0:	4705                	li	a4,1
    800046b2:	04e78963          	beq	a5,a4,80004704 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b6:	470d                	li	a4,3
    800046b8:	04e78d63          	beq	a5,a4,80004712 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046bc:	4709                	li	a4,2
    800046be:	06e79e63          	bne	a5,a4,8000473a <fileread+0xa6>
    ilock(f->ip);
    800046c2:	6d08                	ld	a0,24(a0)
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	ff8080e7          	jalr	-8(ra) # 800036bc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046cc:	874a                	mv	a4,s2
    800046ce:	5094                	lw	a3,32(s1)
    800046d0:	864e                	mv	a2,s3
    800046d2:	4585                	li	a1,1
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	29a080e7          	jalr	666(ra) # 80003970 <readi>
    800046de:	892a                	mv	s2,a0
    800046e0:	00a05563          	blez	a0,800046ea <fileread+0x56>
      f->off += r;
    800046e4:	509c                	lw	a5,32(s1)
    800046e6:	9fa9                	addw	a5,a5,a0
    800046e8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046ea:	6c88                	ld	a0,24(s1)
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	092080e7          	jalr	146(ra) # 8000377e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046f4:	854a                	mv	a0,s2
    800046f6:	70a2                	ld	ra,40(sp)
    800046f8:	7402                	ld	s0,32(sp)
    800046fa:	64e2                	ld	s1,24(sp)
    800046fc:	6942                	ld	s2,16(sp)
    800046fe:	69a2                	ld	s3,8(sp)
    80004700:	6145                	addi	sp,sp,48
    80004702:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004704:	6908                	ld	a0,16(a0)
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	3c0080e7          	jalr	960(ra) # 80004ac6 <piperead>
    8000470e:	892a                	mv	s2,a0
    80004710:	b7d5                	j	800046f4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004712:	02451783          	lh	a5,36(a0)
    80004716:	03079693          	slli	a3,a5,0x30
    8000471a:	92c1                	srli	a3,a3,0x30
    8000471c:	4725                	li	a4,9
    8000471e:	02d76863          	bltu	a4,a3,8000474e <fileread+0xba>
    80004722:	0792                	slli	a5,a5,0x4
    80004724:	0001d717          	auipc	a4,0x1d
    80004728:	bf470713          	addi	a4,a4,-1036 # 80021318 <devsw>
    8000472c:	97ba                	add	a5,a5,a4
    8000472e:	639c                	ld	a5,0(a5)
    80004730:	c38d                	beqz	a5,80004752 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004732:	4505                	li	a0,1
    80004734:	9782                	jalr	a5
    80004736:	892a                	mv	s2,a0
    80004738:	bf75                	j	800046f4 <fileread+0x60>
    panic("fileread");
    8000473a:	00004517          	auipc	a0,0x4
    8000473e:	fee50513          	addi	a0,a0,-18 # 80008728 <syscalls+0x260>
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	df6080e7          	jalr	-522(ra) # 80000538 <panic>
    return -1;
    8000474a:	597d                	li	s2,-1
    8000474c:	b765                	j	800046f4 <fileread+0x60>
      return -1;
    8000474e:	597d                	li	s2,-1
    80004750:	b755                	j	800046f4 <fileread+0x60>
    80004752:	597d                	li	s2,-1
    80004754:	b745                	j	800046f4 <fileread+0x60>

0000000080004756 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004756:	715d                	addi	sp,sp,-80
    80004758:	e486                	sd	ra,72(sp)
    8000475a:	e0a2                	sd	s0,64(sp)
    8000475c:	fc26                	sd	s1,56(sp)
    8000475e:	f84a                	sd	s2,48(sp)
    80004760:	f44e                	sd	s3,40(sp)
    80004762:	f052                	sd	s4,32(sp)
    80004764:	ec56                	sd	s5,24(sp)
    80004766:	e85a                	sd	s6,16(sp)
    80004768:	e45e                	sd	s7,8(sp)
    8000476a:	e062                	sd	s8,0(sp)
    8000476c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000476e:	00954783          	lbu	a5,9(a0)
    80004772:	10078663          	beqz	a5,8000487e <filewrite+0x128>
    80004776:	892a                	mv	s2,a0
    80004778:	8aae                	mv	s5,a1
    8000477a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000477c:	411c                	lw	a5,0(a0)
    8000477e:	4705                	li	a4,1
    80004780:	02e78263          	beq	a5,a4,800047a4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004784:	470d                	li	a4,3
    80004786:	02e78663          	beq	a5,a4,800047b2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000478a:	4709                	li	a4,2
    8000478c:	0ee79163          	bne	a5,a4,8000486e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004790:	0ac05d63          	blez	a2,8000484a <filewrite+0xf4>
    int i = 0;
    80004794:	4981                	li	s3,0
    80004796:	6b05                	lui	s6,0x1
    80004798:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000479c:	6b85                	lui	s7,0x1
    8000479e:	c00b8b9b          	addiw	s7,s7,-1024
    800047a2:	a861                	j	8000483a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047a4:	6908                	ld	a0,16(a0)
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	22e080e7          	jalr	558(ra) # 800049d4 <pipewrite>
    800047ae:	8a2a                	mv	s4,a0
    800047b0:	a045                	j	80004850 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047b2:	02451783          	lh	a5,36(a0)
    800047b6:	03079693          	slli	a3,a5,0x30
    800047ba:	92c1                	srli	a3,a3,0x30
    800047bc:	4725                	li	a4,9
    800047be:	0cd76263          	bltu	a4,a3,80004882 <filewrite+0x12c>
    800047c2:	0792                	slli	a5,a5,0x4
    800047c4:	0001d717          	auipc	a4,0x1d
    800047c8:	b5470713          	addi	a4,a4,-1196 # 80021318 <devsw>
    800047cc:	97ba                	add	a5,a5,a4
    800047ce:	679c                	ld	a5,8(a5)
    800047d0:	cbdd                	beqz	a5,80004886 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047d2:	4505                	li	a0,1
    800047d4:	9782                	jalr	a5
    800047d6:	8a2a                	mv	s4,a0
    800047d8:	a8a5                	j	80004850 <filewrite+0xfa>
    800047da:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	8b0080e7          	jalr	-1872(ra) # 8000408e <begin_op>
      ilock(f->ip);
    800047e6:	01893503          	ld	a0,24(s2)
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	ed2080e7          	jalr	-302(ra) # 800036bc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047f2:	8762                	mv	a4,s8
    800047f4:	02092683          	lw	a3,32(s2)
    800047f8:	01598633          	add	a2,s3,s5
    800047fc:	4585                	li	a1,1
    800047fe:	01893503          	ld	a0,24(s2)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	266080e7          	jalr	614(ra) # 80003a68 <writei>
    8000480a:	84aa                	mv	s1,a0
    8000480c:	00a05763          	blez	a0,8000481a <filewrite+0xc4>
        f->off += r;
    80004810:	02092783          	lw	a5,32(s2)
    80004814:	9fa9                	addw	a5,a5,a0
    80004816:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000481a:	01893503          	ld	a0,24(s2)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	f60080e7          	jalr	-160(ra) # 8000377e <iunlock>
      end_op();
    80004826:	00000097          	auipc	ra,0x0
    8000482a:	8e8080e7          	jalr	-1816(ra) # 8000410e <end_op>

      if(r != n1){
    8000482e:	009c1f63          	bne	s8,s1,8000484c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004832:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004836:	0149db63          	bge	s3,s4,8000484c <filewrite+0xf6>
      int n1 = n - i;
    8000483a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000483e:	84be                	mv	s1,a5
    80004840:	2781                	sext.w	a5,a5
    80004842:	f8fb5ce3          	bge	s6,a5,800047da <filewrite+0x84>
    80004846:	84de                	mv	s1,s7
    80004848:	bf49                	j	800047da <filewrite+0x84>
    int i = 0;
    8000484a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000484c:	013a1f63          	bne	s4,s3,8000486a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004850:	8552                	mv	a0,s4
    80004852:	60a6                	ld	ra,72(sp)
    80004854:	6406                	ld	s0,64(sp)
    80004856:	74e2                	ld	s1,56(sp)
    80004858:	7942                	ld	s2,48(sp)
    8000485a:	79a2                	ld	s3,40(sp)
    8000485c:	7a02                	ld	s4,32(sp)
    8000485e:	6ae2                	ld	s5,24(sp)
    80004860:	6b42                	ld	s6,16(sp)
    80004862:	6ba2                	ld	s7,8(sp)
    80004864:	6c02                	ld	s8,0(sp)
    80004866:	6161                	addi	sp,sp,80
    80004868:	8082                	ret
    ret = (i == n ? n : -1);
    8000486a:	5a7d                	li	s4,-1
    8000486c:	b7d5                	j	80004850 <filewrite+0xfa>
    panic("filewrite");
    8000486e:	00004517          	auipc	a0,0x4
    80004872:	eca50513          	addi	a0,a0,-310 # 80008738 <syscalls+0x270>
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	cc2080e7          	jalr	-830(ra) # 80000538 <panic>
    return -1;
    8000487e:	5a7d                	li	s4,-1
    80004880:	bfc1                	j	80004850 <filewrite+0xfa>
      return -1;
    80004882:	5a7d                	li	s4,-1
    80004884:	b7f1                	j	80004850 <filewrite+0xfa>
    80004886:	5a7d                	li	s4,-1
    80004888:	b7e1                	j	80004850 <filewrite+0xfa>

000000008000488a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000488a:	7179                	addi	sp,sp,-48
    8000488c:	f406                	sd	ra,40(sp)
    8000488e:	f022                	sd	s0,32(sp)
    80004890:	ec26                	sd	s1,24(sp)
    80004892:	e84a                	sd	s2,16(sp)
    80004894:	e44e                	sd	s3,8(sp)
    80004896:	e052                	sd	s4,0(sp)
    80004898:	1800                	addi	s0,sp,48
    8000489a:	84aa                	mv	s1,a0
    8000489c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000489e:	0005b023          	sd	zero,0(a1)
    800048a2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	bf8080e7          	jalr	-1032(ra) # 8000449e <filealloc>
    800048ae:	e088                	sd	a0,0(s1)
    800048b0:	c551                	beqz	a0,8000493c <pipealloc+0xb2>
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	bec080e7          	jalr	-1044(ra) # 8000449e <filealloc>
    800048ba:	00aa3023          	sd	a0,0(s4)
    800048be:	c92d                	beqz	a0,80004930 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	220080e7          	jalr	544(ra) # 80000ae0 <kalloc>
    800048c8:	892a                	mv	s2,a0
    800048ca:	c125                	beqz	a0,8000492a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048cc:	4985                	li	s3,1
    800048ce:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048d2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048d6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048da:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048de:	00004597          	auipc	a1,0x4
    800048e2:	e6a58593          	addi	a1,a1,-406 # 80008748 <syscalls+0x280>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	25a080e7          	jalr	602(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    800048ee:	609c                	ld	a5,0(s1)
    800048f0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048f4:	609c                	ld	a5,0(s1)
    800048f6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048fa:	609c                	ld	a5,0(s1)
    800048fc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004900:	609c                	ld	a5,0(s1)
    80004902:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004906:	000a3783          	ld	a5,0(s4)
    8000490a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000490e:	000a3783          	ld	a5,0(s4)
    80004912:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004916:	000a3783          	ld	a5,0(s4)
    8000491a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000491e:	000a3783          	ld	a5,0(s4)
    80004922:	0127b823          	sd	s2,16(a5)
  return 0;
    80004926:	4501                	li	a0,0
    80004928:	a025                	j	80004950 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000492a:	6088                	ld	a0,0(s1)
    8000492c:	e501                	bnez	a0,80004934 <pipealloc+0xaa>
    8000492e:	a039                	j	8000493c <pipealloc+0xb2>
    80004930:	6088                	ld	a0,0(s1)
    80004932:	c51d                	beqz	a0,80004960 <pipealloc+0xd6>
    fileclose(*f0);
    80004934:	00000097          	auipc	ra,0x0
    80004938:	c26080e7          	jalr	-986(ra) # 8000455a <fileclose>
  if(*f1)
    8000493c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004940:	557d                	li	a0,-1
  if(*f1)
    80004942:	c799                	beqz	a5,80004950 <pipealloc+0xc6>
    fileclose(*f1);
    80004944:	853e                	mv	a0,a5
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	c14080e7          	jalr	-1004(ra) # 8000455a <fileclose>
  return -1;
    8000494e:	557d                	li	a0,-1
}
    80004950:	70a2                	ld	ra,40(sp)
    80004952:	7402                	ld	s0,32(sp)
    80004954:	64e2                	ld	s1,24(sp)
    80004956:	6942                	ld	s2,16(sp)
    80004958:	69a2                	ld	s3,8(sp)
    8000495a:	6a02                	ld	s4,0(sp)
    8000495c:	6145                	addi	sp,sp,48
    8000495e:	8082                	ret
  return -1;
    80004960:	557d                	li	a0,-1
    80004962:	b7fd                	j	80004950 <pipealloc+0xc6>

0000000080004964 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004964:	1101                	addi	sp,sp,-32
    80004966:	ec06                	sd	ra,24(sp)
    80004968:	e822                	sd	s0,16(sp)
    8000496a:	e426                	sd	s1,8(sp)
    8000496c:	e04a                	sd	s2,0(sp)
    8000496e:	1000                	addi	s0,sp,32
    80004970:	84aa                	mv	s1,a0
    80004972:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	25c080e7          	jalr	604(ra) # 80000bd0 <acquire>
  if(writable){
    8000497c:	02090d63          	beqz	s2,800049b6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004980:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004984:	21848513          	addi	a0,s1,536
    80004988:	ffffe097          	auipc	ra,0xffffe
    8000498c:	85a080e7          	jalr	-1958(ra) # 800021e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004990:	2204b783          	ld	a5,544(s1)
    80004994:	eb95                	bnez	a5,800049c8 <pipeclose+0x64>
    release(&pi->lock);
    80004996:	8526                	mv	a0,s1
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	2ec080e7          	jalr	748(ra) # 80000c84 <release>
    kfree((char*)pi);
    800049a0:	8526                	mv	a0,s1
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	042080e7          	jalr	66(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    800049aa:	60e2                	ld	ra,24(sp)
    800049ac:	6442                	ld	s0,16(sp)
    800049ae:	64a2                	ld	s1,8(sp)
    800049b0:	6902                	ld	s2,0(sp)
    800049b2:	6105                	addi	sp,sp,32
    800049b4:	8082                	ret
    pi->readopen = 0;
    800049b6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049ba:	21c48513          	addi	a0,s1,540
    800049be:	ffffe097          	auipc	ra,0xffffe
    800049c2:	824080e7          	jalr	-2012(ra) # 800021e2 <wakeup>
    800049c6:	b7e9                	j	80004990 <pipeclose+0x2c>
    release(&pi->lock);
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	2ba080e7          	jalr	698(ra) # 80000c84 <release>
}
    800049d2:	bfe1                	j	800049aa <pipeclose+0x46>

00000000800049d4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049d4:	711d                	addi	sp,sp,-96
    800049d6:	ec86                	sd	ra,88(sp)
    800049d8:	e8a2                	sd	s0,80(sp)
    800049da:	e4a6                	sd	s1,72(sp)
    800049dc:	e0ca                	sd	s2,64(sp)
    800049de:	fc4e                	sd	s3,56(sp)
    800049e0:	f852                	sd	s4,48(sp)
    800049e2:	f456                	sd	s5,40(sp)
    800049e4:	f05a                	sd	s6,32(sp)
    800049e6:	ec5e                	sd	s7,24(sp)
    800049e8:	e862                	sd	s8,16(sp)
    800049ea:	1080                	addi	s0,sp,96
    800049ec:	84aa                	mv	s1,a0
    800049ee:	8aae                	mv	s5,a1
    800049f0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049f2:	ffffd097          	auipc	ra,0xffffd
    800049f6:	fa4080e7          	jalr	-92(ra) # 80001996 <myproc>
    800049fa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	1d2080e7          	jalr	466(ra) # 80000bd0 <acquire>
  while(i < n){
    80004a06:	0b405363          	blez	s4,80004aac <pipewrite+0xd8>
  int i = 0;
    80004a0a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a0c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a0e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a12:	21c48b93          	addi	s7,s1,540
    80004a16:	a089                	j	80004a58 <pipewrite+0x84>
      release(&pi->lock);
    80004a18:	8526                	mv	a0,s1
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	26a080e7          	jalr	618(ra) # 80000c84 <release>
      return -1;
    80004a22:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a24:	854a                	mv	a0,s2
    80004a26:	60e6                	ld	ra,88(sp)
    80004a28:	6446                	ld	s0,80(sp)
    80004a2a:	64a6                	ld	s1,72(sp)
    80004a2c:	6906                	ld	s2,64(sp)
    80004a2e:	79e2                	ld	s3,56(sp)
    80004a30:	7a42                	ld	s4,48(sp)
    80004a32:	7aa2                	ld	s5,40(sp)
    80004a34:	7b02                	ld	s6,32(sp)
    80004a36:	6be2                	ld	s7,24(sp)
    80004a38:	6c42                	ld	s8,16(sp)
    80004a3a:	6125                	addi	sp,sp,96
    80004a3c:	8082                	ret
      wakeup(&pi->nread);
    80004a3e:	8562                	mv	a0,s8
    80004a40:	ffffd097          	auipc	ra,0xffffd
    80004a44:	7a2080e7          	jalr	1954(ra) # 800021e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a48:	85a6                	mv	a1,s1
    80004a4a:	855e                	mv	a0,s7
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	60a080e7          	jalr	1546(ra) # 80002056 <sleep>
  while(i < n){
    80004a54:	05495d63          	bge	s2,s4,80004aae <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a58:	2204a783          	lw	a5,544(s1)
    80004a5c:	dfd5                	beqz	a5,80004a18 <pipewrite+0x44>
    80004a5e:	0289a783          	lw	a5,40(s3)
    80004a62:	fbdd                	bnez	a5,80004a18 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a64:	2184a783          	lw	a5,536(s1)
    80004a68:	21c4a703          	lw	a4,540(s1)
    80004a6c:	2007879b          	addiw	a5,a5,512
    80004a70:	fcf707e3          	beq	a4,a5,80004a3e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a74:	4685                	li	a3,1
    80004a76:	01590633          	add	a2,s2,s5
    80004a7a:	faf40593          	addi	a1,s0,-81
    80004a7e:	0509b503          	ld	a0,80(s3)
    80004a82:	ffffd097          	auipc	ra,0xffffd
    80004a86:	c60080e7          	jalr	-928(ra) # 800016e2 <copyin>
    80004a8a:	03650263          	beq	a0,s6,80004aae <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a8e:	21c4a783          	lw	a5,540(s1)
    80004a92:	0017871b          	addiw	a4,a5,1
    80004a96:	20e4ae23          	sw	a4,540(s1)
    80004a9a:	1ff7f793          	andi	a5,a5,511
    80004a9e:	97a6                	add	a5,a5,s1
    80004aa0:	faf44703          	lbu	a4,-81(s0)
    80004aa4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004aa8:	2905                	addiw	s2,s2,1
    80004aaa:	b76d                	j	80004a54 <pipewrite+0x80>
  int i = 0;
    80004aac:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004aae:	21848513          	addi	a0,s1,536
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	730080e7          	jalr	1840(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004aba:	8526                	mv	a0,s1
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	1c8080e7          	jalr	456(ra) # 80000c84 <release>
  return i;
    80004ac4:	b785                	j	80004a24 <pipewrite+0x50>

0000000080004ac6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ac6:	715d                	addi	sp,sp,-80
    80004ac8:	e486                	sd	ra,72(sp)
    80004aca:	e0a2                	sd	s0,64(sp)
    80004acc:	fc26                	sd	s1,56(sp)
    80004ace:	f84a                	sd	s2,48(sp)
    80004ad0:	f44e                	sd	s3,40(sp)
    80004ad2:	f052                	sd	s4,32(sp)
    80004ad4:	ec56                	sd	s5,24(sp)
    80004ad6:	e85a                	sd	s6,16(sp)
    80004ad8:	0880                	addi	s0,sp,80
    80004ada:	84aa                	mv	s1,a0
    80004adc:	892e                	mv	s2,a1
    80004ade:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ae0:	ffffd097          	auipc	ra,0xffffd
    80004ae4:	eb6080e7          	jalr	-330(ra) # 80001996 <myproc>
    80004ae8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	0e4080e7          	jalr	228(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004af4:	2184a703          	lw	a4,536(s1)
    80004af8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004afc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b00:	02f71463          	bne	a4,a5,80004b28 <piperead+0x62>
    80004b04:	2244a783          	lw	a5,548(s1)
    80004b08:	c385                	beqz	a5,80004b28 <piperead+0x62>
    if(pr->killed){
    80004b0a:	028a2783          	lw	a5,40(s4)
    80004b0e:	ebc1                	bnez	a5,80004b9e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b10:	85a6                	mv	a1,s1
    80004b12:	854e                	mv	a0,s3
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	542080e7          	jalr	1346(ra) # 80002056 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1c:	2184a703          	lw	a4,536(s1)
    80004b20:	21c4a783          	lw	a5,540(s1)
    80004b24:	fef700e3          	beq	a4,a5,80004b04 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b28:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b2a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b2c:	05505363          	blez	s5,80004b72 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b30:	2184a783          	lw	a5,536(s1)
    80004b34:	21c4a703          	lw	a4,540(s1)
    80004b38:	02f70d63          	beq	a4,a5,80004b72 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b3c:	0017871b          	addiw	a4,a5,1
    80004b40:	20e4ac23          	sw	a4,536(s1)
    80004b44:	1ff7f793          	andi	a5,a5,511
    80004b48:	97a6                	add	a5,a5,s1
    80004b4a:	0187c783          	lbu	a5,24(a5)
    80004b4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b52:	4685                	li	a3,1
    80004b54:	fbf40613          	addi	a2,s0,-65
    80004b58:	85ca                	mv	a1,s2
    80004b5a:	050a3503          	ld	a0,80(s4)
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	af8080e7          	jalr	-1288(ra) # 80001656 <copyout>
    80004b66:	01650663          	beq	a0,s6,80004b72 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6a:	2985                	addiw	s3,s3,1
    80004b6c:	0905                	addi	s2,s2,1
    80004b6e:	fd3a91e3          	bne	s5,s3,80004b30 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b72:	21c48513          	addi	a0,s1,540
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	66c080e7          	jalr	1644(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	104080e7          	jalr	260(ra) # 80000c84 <release>
  return i;
}
    80004b88:	854e                	mv	a0,s3
    80004b8a:	60a6                	ld	ra,72(sp)
    80004b8c:	6406                	ld	s0,64(sp)
    80004b8e:	74e2                	ld	s1,56(sp)
    80004b90:	7942                	ld	s2,48(sp)
    80004b92:	79a2                	ld	s3,40(sp)
    80004b94:	7a02                	ld	s4,32(sp)
    80004b96:	6ae2                	ld	s5,24(sp)
    80004b98:	6b42                	ld	s6,16(sp)
    80004b9a:	6161                	addi	sp,sp,80
    80004b9c:	8082                	ret
      release(&pi->lock);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	0e4080e7          	jalr	228(ra) # 80000c84 <release>
      return -1;
    80004ba8:	59fd                	li	s3,-1
    80004baa:	bff9                	j	80004b88 <piperead+0xc2>

0000000080004bac <exec>:
#include "elf.h"

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int exec(char *path, char **argv)
{
    80004bac:	de010113          	addi	sp,sp,-544
    80004bb0:	20113c23          	sd	ra,536(sp)
    80004bb4:	20813823          	sd	s0,528(sp)
    80004bb8:	20913423          	sd	s1,520(sp)
    80004bbc:	21213023          	sd	s2,512(sp)
    80004bc0:	ffce                	sd	s3,504(sp)
    80004bc2:	fbd2                	sd	s4,496(sp)
    80004bc4:	f7d6                	sd	s5,488(sp)
    80004bc6:	f3da                	sd	s6,480(sp)
    80004bc8:	efde                	sd	s7,472(sp)
    80004bca:	ebe2                	sd	s8,464(sp)
    80004bcc:	e7e6                	sd	s9,456(sp)
    80004bce:	e3ea                	sd	s10,448(sp)
    80004bd0:	ff6e                	sd	s11,440(sp)
    80004bd2:	1400                	addi	s0,sp,544
    80004bd4:	892a                	mv	s2,a0
    80004bd6:	dea43423          	sd	a0,-536(s0)
    80004bda:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	db8080e7          	jalr	-584(ra) # 80001996 <myproc>
    80004be6:	84aa                	mv	s1,a0

  begin_op();
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	4a6080e7          	jalr	1190(ra) # 8000408e <begin_op>

  if ((ip = namei(path)) == 0)
    80004bf0:	854a                	mv	a0,s2
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	280080e7          	jalr	640(ra) # 80003e72 <namei>
    80004bfa:	c93d                	beqz	a0,80004c70 <exec+0xc4>
    80004bfc:	8aaa                	mv	s5,a0
  {
    end_op();
    return -1;
  }
  ilock(ip);
    80004bfe:	fffff097          	auipc	ra,0xfffff
    80004c02:	abe080e7          	jalr	-1346(ra) # 800036bc <ilock>

  // Check ELF header
  if (readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c06:	04000713          	li	a4,64
    80004c0a:	4681                	li	a3,0
    80004c0c:	e5040613          	addi	a2,s0,-432
    80004c10:	4581                	li	a1,0
    80004c12:	8556                	mv	a0,s5
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	d5c080e7          	jalr	-676(ra) # 80003970 <readi>
    80004c1c:	04000793          	li	a5,64
    80004c20:	00f51a63          	bne	a0,a5,80004c34 <exec+0x88>
    goto bad;
  if (elf.magic != ELF_MAGIC)
    80004c24:	e5042703          	lw	a4,-432(s0)
    80004c28:	464c47b7          	lui	a5,0x464c4
    80004c2c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c30:	04f70663          	beq	a4,a5,80004c7c <exec+0xd0>
bad:
  if (pagetable)
    proc_freepagetable(pagetable, sz);
  if (ip)
  {
    iunlockput(ip);
    80004c34:	8556                	mv	a0,s5
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	ce8080e7          	jalr	-792(ra) # 8000391e <iunlockput>
    end_op();
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	4d0080e7          	jalr	1232(ra) # 8000410e <end_op>
  }
  return -1;
    80004c46:	557d                	li	a0,-1
}
    80004c48:	21813083          	ld	ra,536(sp)
    80004c4c:	21013403          	ld	s0,528(sp)
    80004c50:	20813483          	ld	s1,520(sp)
    80004c54:	20013903          	ld	s2,512(sp)
    80004c58:	79fe                	ld	s3,504(sp)
    80004c5a:	7a5e                	ld	s4,496(sp)
    80004c5c:	7abe                	ld	s5,488(sp)
    80004c5e:	7b1e                	ld	s6,480(sp)
    80004c60:	6bfe                	ld	s7,472(sp)
    80004c62:	6c5e                	ld	s8,464(sp)
    80004c64:	6cbe                	ld	s9,456(sp)
    80004c66:	6d1e                	ld	s10,448(sp)
    80004c68:	7dfa                	ld	s11,440(sp)
    80004c6a:	22010113          	addi	sp,sp,544
    80004c6e:	8082                	ret
    end_op();
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	49e080e7          	jalr	1182(ra) # 8000410e <end_op>
    return -1;
    80004c78:	557d                	li	a0,-1
    80004c7a:	b7f9                	j	80004c48 <exec+0x9c>
  if ((pagetable = proc_pagetable(p)) == 0)
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	ddc080e7          	jalr	-548(ra) # 80001a5a <proc_pagetable>
    80004c86:	8b2a                	mv	s6,a0
    80004c88:	d555                	beqz	a0,80004c34 <exec+0x88>
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    80004c8a:	e7042783          	lw	a5,-400(s0)
    80004c8e:	e8845703          	lhu	a4,-376(s0)
    80004c92:	c735                	beqz	a4,80004cfe <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c94:	4481                	li	s1,0
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    80004c96:	e0043423          	sd	zero,-504(s0)
    if ((ph.vaddr % PGSIZE) != 0)
    80004c9a:	6a05                	lui	s4,0x1
    80004c9c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ca0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for (i = 0; i < sz; i += PGSIZE)
    80004ca4:	6d85                	lui	s11,0x1
    80004ca6:	7d7d                	lui	s10,0xfffff
    80004ca8:	ac1d                	j	80004ede <exec+0x332>
  {
    pa = walkaddr(pagetable, va + i);
    if (pa == 0)
      panic("loadseg: address should exist");
    80004caa:	00004517          	auipc	a0,0x4
    80004cae:	aa650513          	addi	a0,a0,-1370 # 80008750 <syscalls+0x288>
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	886080e7          	jalr	-1914(ra) # 80000538 <panic>
    if (sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if (readi(ip, 0, (uint64)pa, offset + i, n) != n)
    80004cba:	874a                	mv	a4,s2
    80004cbc:	009c86bb          	addw	a3,s9,s1
    80004cc0:	4581                	li	a1,0
    80004cc2:	8556                	mv	a0,s5
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	cac080e7          	jalr	-852(ra) # 80003970 <readi>
    80004ccc:	2501                	sext.w	a0,a0
    80004cce:	1aa91863          	bne	s2,a0,80004e7e <exec+0x2d2>
  for (i = 0; i < sz; i += PGSIZE)
    80004cd2:	009d84bb          	addw	s1,s11,s1
    80004cd6:	013d09bb          	addw	s3,s10,s3
    80004cda:	1f74f263          	bgeu	s1,s7,80004ebe <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004cde:	02049593          	slli	a1,s1,0x20
    80004ce2:	9181                	srli	a1,a1,0x20
    80004ce4:	95e2                	add	a1,a1,s8
    80004ce6:	855a                	mv	a0,s6
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	36a080e7          	jalr	874(ra) # 80001052 <walkaddr>
    80004cf0:	862a                	mv	a2,a0
    if (pa == 0)
    80004cf2:	dd45                	beqz	a0,80004caa <exec+0xfe>
      n = PGSIZE;
    80004cf4:	8952                	mv	s2,s4
    if (sz - i < PGSIZE)
    80004cf6:	fd49f2e3          	bgeu	s3,s4,80004cba <exec+0x10e>
      n = sz - i;
    80004cfa:	894e                	mv	s2,s3
    80004cfc:	bf7d                	j	80004cba <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cfe:	4481                	li	s1,0
  iunlockput(ip);
    80004d00:	8556                	mv	a0,s5
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	c1c080e7          	jalr	-996(ra) # 8000391e <iunlockput>
  end_op();
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	404080e7          	jalr	1028(ra) # 8000410e <end_op>
  p = myproc();
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	c84080e7          	jalr	-892(ra) # 80001996 <myproc>
    80004d1a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d1c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d20:	6785                	lui	a5,0x1
    80004d22:	17fd                	addi	a5,a5,-1
    80004d24:	94be                	add	s1,s1,a5
    80004d26:	77fd                	lui	a5,0xfffff
    80004d28:	8fe5                	and	a5,a5,s1
    80004d2a:	def43c23          	sd	a5,-520(s0)
  if ((sz1 = uvmalloc(pagetable, sz, sz + 2 * PGSIZE)) == 0)
    80004d2e:	6609                	lui	a2,0x2
    80004d30:	963e                	add	a2,a2,a5
    80004d32:	85be                	mv	a1,a5
    80004d34:	855a                	mv	a0,s6
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	6d0080e7          	jalr	1744(ra) # 80001406 <uvmalloc>
    80004d3e:	8c2a                	mv	s8,a0
  ip = 0;
    80004d40:	4a81                	li	s5,0
  if ((sz1 = uvmalloc(pagetable, sz, sz + 2 * PGSIZE)) == 0)
    80004d42:	12050e63          	beqz	a0,80004e7e <exec+0x2d2>
  uvmclear(pagetable, sz - 2 * PGSIZE);
    80004d46:	75f9                	lui	a1,0xffffe
    80004d48:	95aa                	add	a1,a1,a0
    80004d4a:	855a                	mv	a0,s6
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	8d8080e7          	jalr	-1832(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d54:	7afd                	lui	s5,0xfffff
    80004d56:	9ae2                	add	s5,s5,s8
  for (argc = 0; argv[argc]; argc++)
    80004d58:	df043783          	ld	a5,-528(s0)
    80004d5c:	6388                	ld	a0,0(a5)
    80004d5e:	c925                	beqz	a0,80004dce <exec+0x222>
    80004d60:	e9040993          	addi	s3,s0,-368
    80004d64:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d68:	8962                	mv	s2,s8
  for (argc = 0; argv[argc]; argc++)
    80004d6a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	0dc080e7          	jalr	220(ra) # 80000e48 <strlen>
    80004d74:	0015079b          	addiw	a5,a0,1
    80004d78:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d7c:	ff097913          	andi	s2,s2,-16
    if (sp < stackbase)
    80004d80:	13596363          	bltu	s2,s5,80004ea6 <exec+0x2fa>
    if (copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d84:	df043d83          	ld	s11,-528(s0)
    80004d88:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d8c:	8552                	mv	a0,s4
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	0ba080e7          	jalr	186(ra) # 80000e48 <strlen>
    80004d96:	0015069b          	addiw	a3,a0,1
    80004d9a:	8652                	mv	a2,s4
    80004d9c:	85ca                	mv	a1,s2
    80004d9e:	855a                	mv	a0,s6
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	8b6080e7          	jalr	-1866(ra) # 80001656 <copyout>
    80004da8:	10054363          	bltz	a0,80004eae <exec+0x302>
    ustack[argc] = sp;
    80004dac:	0129b023          	sd	s2,0(s3)
  for (argc = 0; argv[argc]; argc++)
    80004db0:	0485                	addi	s1,s1,1
    80004db2:	008d8793          	addi	a5,s11,8
    80004db6:	def43823          	sd	a5,-528(s0)
    80004dba:	008db503          	ld	a0,8(s11)
    80004dbe:	c911                	beqz	a0,80004dd2 <exec+0x226>
    if (argc >= MAXARG)
    80004dc0:	09a1                	addi	s3,s3,8
    80004dc2:	fb3c95e3          	bne	s9,s3,80004d6c <exec+0x1c0>
  sz = sz1;
    80004dc6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dca:	4a81                	li	s5,0
    80004dcc:	a84d                	j	80004e7e <exec+0x2d2>
  sp = sz;
    80004dce:	8962                	mv	s2,s8
  for (argc = 0; argv[argc]; argc++)
    80004dd0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dd2:	00349793          	slli	a5,s1,0x3
    80004dd6:	f9040713          	addi	a4,s0,-112
    80004dda:	97ba                	add	a5,a5,a4
    80004ddc:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd8f00>
  sp -= (argc + 1) * sizeof(uint64);
    80004de0:	00148693          	addi	a3,s1,1
    80004de4:	068e                	slli	a3,a3,0x3
    80004de6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dea:	ff097913          	andi	s2,s2,-16
  if (sp < stackbase)
    80004dee:	01597663          	bgeu	s2,s5,80004dfa <exec+0x24e>
  sz = sz1;
    80004df2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004df6:	4a81                	li	s5,0
    80004df8:	a059                	j	80004e7e <exec+0x2d2>
  if (copyout(pagetable, sp, (char *)ustack, (argc + 1) * sizeof(uint64)) < 0)
    80004dfa:	e9040613          	addi	a2,s0,-368
    80004dfe:	85ca                	mv	a1,s2
    80004e00:	855a                	mv	a0,s6
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	854080e7          	jalr	-1964(ra) # 80001656 <copyout>
    80004e0a:	0a054663          	bltz	a0,80004eb6 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e0e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e12:	0727bc23          	sd	s2,120(a5)
  for (last = s = path; *s; s++)
    80004e16:	de843783          	ld	a5,-536(s0)
    80004e1a:	0007c703          	lbu	a4,0(a5)
    80004e1e:	cf11                	beqz	a4,80004e3a <exec+0x28e>
    80004e20:	0785                	addi	a5,a5,1
    if (*s == '/')
    80004e22:	02f00693          	li	a3,47
    80004e26:	a039                	j	80004e34 <exec+0x288>
      last = s + 1;
    80004e28:	def43423          	sd	a5,-536(s0)
  for (last = s = path; *s; s++)
    80004e2c:	0785                	addi	a5,a5,1
    80004e2e:	fff7c703          	lbu	a4,-1(a5)
    80004e32:	c701                	beqz	a4,80004e3a <exec+0x28e>
    if (*s == '/')
    80004e34:	fed71ce3          	bne	a4,a3,80004e2c <exec+0x280>
    80004e38:	bfc5                	j	80004e28 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e3a:	4641                	li	a2,16
    80004e3c:	de843583          	ld	a1,-536(s0)
    80004e40:	158b8513          	addi	a0,s7,344
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	fd2080e7          	jalr	-46(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e4c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e50:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e54:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry; // initial program counter = main
    80004e58:	058bb783          	ld	a5,88(s7)
    80004e5c:	e6843703          	ld	a4,-408(s0)
    80004e60:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp;         // initial stack pointer
    80004e62:	058bb783          	ld	a5,88(s7)
    80004e66:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e6a:	85ea                	mv	a1,s10
    80004e6c:	ffffd097          	auipc	ra,0xffffd
    80004e70:	c8a080e7          	jalr	-886(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e74:	0004851b          	sext.w	a0,s1
    80004e78:	bbc1                	j	80004c48 <exec+0x9c>
    80004e7a:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e7e:	df843583          	ld	a1,-520(s0)
    80004e82:	855a                	mv	a0,s6
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	c72080e7          	jalr	-910(ra) # 80001af6 <proc_freepagetable>
  if (ip)
    80004e8c:	da0a94e3          	bnez	s5,80004c34 <exec+0x88>
  return -1;
    80004e90:	557d                	li	a0,-1
    80004e92:	bb5d                	j	80004c48 <exec+0x9c>
    80004e94:	de943c23          	sd	s1,-520(s0)
    80004e98:	b7dd                	j	80004e7e <exec+0x2d2>
    80004e9a:	de943c23          	sd	s1,-520(s0)
    80004e9e:	b7c5                	j	80004e7e <exec+0x2d2>
    80004ea0:	de943c23          	sd	s1,-520(s0)
    80004ea4:	bfe9                	j	80004e7e <exec+0x2d2>
  sz = sz1;
    80004ea6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eaa:	4a81                	li	s5,0
    80004eac:	bfc9                	j	80004e7e <exec+0x2d2>
  sz = sz1;
    80004eae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eb2:	4a81                	li	s5,0
    80004eb4:	b7e9                	j	80004e7e <exec+0x2d2>
  sz = sz1;
    80004eb6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eba:	4a81                	li	s5,0
    80004ebc:	b7c9                	j	80004e7e <exec+0x2d2>
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ebe:	df843483          	ld	s1,-520(s0)
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    80004ec2:	e0843783          	ld	a5,-504(s0)
    80004ec6:	0017869b          	addiw	a3,a5,1
    80004eca:	e0d43423          	sd	a3,-504(s0)
    80004ece:	e0043783          	ld	a5,-512(s0)
    80004ed2:	0387879b          	addiw	a5,a5,56
    80004ed6:	e8845703          	lhu	a4,-376(s0)
    80004eda:	e2e6d3e3          	bge	a3,a4,80004d00 <exec+0x154>
    if (readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ede:	2781                	sext.w	a5,a5
    80004ee0:	e0f43023          	sd	a5,-512(s0)
    80004ee4:	03800713          	li	a4,56
    80004ee8:	86be                	mv	a3,a5
    80004eea:	e1840613          	addi	a2,s0,-488
    80004eee:	4581                	li	a1,0
    80004ef0:	8556                	mv	a0,s5
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	a7e080e7          	jalr	-1410(ra) # 80003970 <readi>
    80004efa:	03800793          	li	a5,56
    80004efe:	f6f51ee3          	bne	a0,a5,80004e7a <exec+0x2ce>
    if (ph.type != ELF_PROG_LOAD)
    80004f02:	e1842783          	lw	a5,-488(s0)
    80004f06:	4705                	li	a4,1
    80004f08:	fae79de3          	bne	a5,a4,80004ec2 <exec+0x316>
    if (ph.memsz < ph.filesz)
    80004f0c:	e4043603          	ld	a2,-448(s0)
    80004f10:	e3843783          	ld	a5,-456(s0)
    80004f14:	f8f660e3          	bltu	a2,a5,80004e94 <exec+0x2e8>
    if (ph.vaddr + ph.memsz < ph.vaddr)
    80004f18:	e2843783          	ld	a5,-472(s0)
    80004f1c:	963e                	add	a2,a2,a5
    80004f1e:	f6f66ee3          	bltu	a2,a5,80004e9a <exec+0x2ee>
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f22:	85a6                	mv	a1,s1
    80004f24:	855a                	mv	a0,s6
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	4e0080e7          	jalr	1248(ra) # 80001406 <uvmalloc>
    80004f2e:	dea43c23          	sd	a0,-520(s0)
    80004f32:	d53d                	beqz	a0,80004ea0 <exec+0x2f4>
    if ((ph.vaddr % PGSIZE) != 0)
    80004f34:	e2843c03          	ld	s8,-472(s0)
    80004f38:	de043783          	ld	a5,-544(s0)
    80004f3c:	00fc77b3          	and	a5,s8,a5
    80004f40:	ff9d                	bnez	a5,80004e7e <exec+0x2d2>
    if (loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f42:	e2042c83          	lw	s9,-480(s0)
    80004f46:	e3842b83          	lw	s7,-456(s0)
  for (i = 0; i < sz; i += PGSIZE)
    80004f4a:	f60b8ae3          	beqz	s7,80004ebe <exec+0x312>
    80004f4e:	89de                	mv	s3,s7
    80004f50:	4481                	li	s1,0
    80004f52:	b371                	j	80004cde <exec+0x132>

0000000080004f54 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f54:	7179                	addi	sp,sp,-48
    80004f56:	f406                	sd	ra,40(sp)
    80004f58:	f022                	sd	s0,32(sp)
    80004f5a:	ec26                	sd	s1,24(sp)
    80004f5c:	e84a                	sd	s2,16(sp)
    80004f5e:	1800                	addi	s0,sp,48
    80004f60:	892e                	mv	s2,a1
    80004f62:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if (argint(n, &fd) < 0)
    80004f64:	fdc40593          	addi	a1,s0,-36
    80004f68:	ffffe097          	auipc	ra,0xffffe
    80004f6c:	bca080e7          	jalr	-1078(ra) # 80002b32 <argint>
    80004f70:	04054063          	bltz	a0,80004fb0 <argfd+0x5c>
    return -1;
  if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    80004f74:	fdc42703          	lw	a4,-36(s0)
    80004f78:	47bd                	li	a5,15
    80004f7a:	02e7ed63          	bltu	a5,a4,80004fb4 <argfd+0x60>
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	a18080e7          	jalr	-1512(ra) # 80001996 <myproc>
    80004f86:	fdc42703          	lw	a4,-36(s0)
    80004f8a:	01a70793          	addi	a5,a4,26
    80004f8e:	078e                	slli	a5,a5,0x3
    80004f90:	953e                	add	a0,a0,a5
    80004f92:	611c                	ld	a5,0(a0)
    80004f94:	c395                	beqz	a5,80004fb8 <argfd+0x64>
    return -1;
  if (pfd)
    80004f96:	00090463          	beqz	s2,80004f9e <argfd+0x4a>
    *pfd = fd;
    80004f9a:	00e92023          	sw	a4,0(s2)
  if (pf)
    *pf = f;
  return 0;
    80004f9e:	4501                	li	a0,0
  if (pf)
    80004fa0:	c091                	beqz	s1,80004fa4 <argfd+0x50>
    *pf = f;
    80004fa2:	e09c                	sd	a5,0(s1)
}
    80004fa4:	70a2                	ld	ra,40(sp)
    80004fa6:	7402                	ld	s0,32(sp)
    80004fa8:	64e2                	ld	s1,24(sp)
    80004faa:	6942                	ld	s2,16(sp)
    80004fac:	6145                	addi	sp,sp,48
    80004fae:	8082                	ret
    return -1;
    80004fb0:	557d                	li	a0,-1
    80004fb2:	bfcd                	j	80004fa4 <argfd+0x50>
    return -1;
    80004fb4:	557d                	li	a0,-1
    80004fb6:	b7fd                	j	80004fa4 <argfd+0x50>
    80004fb8:	557d                	li	a0,-1
    80004fba:	b7ed                	j	80004fa4 <argfd+0x50>

0000000080004fbc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fbc:	1101                	addi	sp,sp,-32
    80004fbe:	ec06                	sd	ra,24(sp)
    80004fc0:	e822                	sd	s0,16(sp)
    80004fc2:	e426                	sd	s1,8(sp)
    80004fc4:	1000                	addi	s0,sp,32
    80004fc6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	9ce080e7          	jalr	-1586(ra) # 80001996 <myproc>
    80004fd0:	862a                	mv	a2,a0

  for (fd = 0; fd < NOFILE; fd++)
    80004fd2:	0d050793          	addi	a5,a0,208
    80004fd6:	4501                	li	a0,0
    80004fd8:	46c1                	li	a3,16
  {
    if (p->ofile[fd] == 0)
    80004fda:	6398                	ld	a4,0(a5)
    80004fdc:	cb19                	beqz	a4,80004ff2 <fdalloc+0x36>
  for (fd = 0; fd < NOFILE; fd++)
    80004fde:	2505                	addiw	a0,a0,1
    80004fe0:	07a1                	addi	a5,a5,8
    80004fe2:	fed51ce3          	bne	a0,a3,80004fda <fdalloc+0x1e>
    {
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fe6:	557d                	li	a0,-1
}
    80004fe8:	60e2                	ld	ra,24(sp)
    80004fea:	6442                	ld	s0,16(sp)
    80004fec:	64a2                	ld	s1,8(sp)
    80004fee:	6105                	addi	sp,sp,32
    80004ff0:	8082                	ret
      p->ofile[fd] = f;
    80004ff2:	01a50793          	addi	a5,a0,26
    80004ff6:	078e                	slli	a5,a5,0x3
    80004ff8:	963e                	add	a2,a2,a5
    80004ffa:	e204                	sd	s1,0(a2)
      return fd;
    80004ffc:	b7f5                	j	80004fe8 <fdalloc+0x2c>

0000000080004ffe <create>:
  return -1;
}

static struct inode *
create(char *path, short type, short major, short minor)
{
    80004ffe:	715d                	addi	sp,sp,-80
    80005000:	e486                	sd	ra,72(sp)
    80005002:	e0a2                	sd	s0,64(sp)
    80005004:	fc26                	sd	s1,56(sp)
    80005006:	f84a                	sd	s2,48(sp)
    80005008:	f44e                	sd	s3,40(sp)
    8000500a:	f052                	sd	s4,32(sp)
    8000500c:	ec56                	sd	s5,24(sp)
    8000500e:	0880                	addi	s0,sp,80
    80005010:	89ae                	mv	s3,a1
    80005012:	8ab2                	mv	s5,a2
    80005014:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if ((dp = nameiparent(path, name)) == 0)
    80005016:	fb040593          	addi	a1,s0,-80
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	e76080e7          	jalr	-394(ra) # 80003e90 <nameiparent>
    80005022:	892a                	mv	s2,a0
    80005024:	12050e63          	beqz	a0,80005160 <create+0x162>
    return 0;

  ilock(dp);
    80005028:	ffffe097          	auipc	ra,0xffffe
    8000502c:	694080e7          	jalr	1684(ra) # 800036bc <ilock>

  if ((ip = dirlookup(dp, name, 0)) != 0)
    80005030:	4601                	li	a2,0
    80005032:	fb040593          	addi	a1,s0,-80
    80005036:	854a                	mv	a0,s2
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	b68080e7          	jalr	-1176(ra) # 80003ba0 <dirlookup>
    80005040:	84aa                	mv	s1,a0
    80005042:	c921                	beqz	a0,80005092 <create+0x94>
  {
    iunlockput(dp);
    80005044:	854a                	mv	a0,s2
    80005046:	fffff097          	auipc	ra,0xfffff
    8000504a:	8d8080e7          	jalr	-1832(ra) # 8000391e <iunlockput>
    ilock(ip);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffe097          	auipc	ra,0xffffe
    80005054:	66c080e7          	jalr	1644(ra) # 800036bc <ilock>
    if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005058:	2981                	sext.w	s3,s3
    8000505a:	4789                	li	a5,2
    8000505c:	02f99463          	bne	s3,a5,80005084 <create+0x86>
    80005060:	0444d783          	lhu	a5,68(s1)
    80005064:	37f9                	addiw	a5,a5,-2
    80005066:	17c2                	slli	a5,a5,0x30
    80005068:	93c1                	srli	a5,a5,0x30
    8000506a:	4705                	li	a4,1
    8000506c:	00f76c63          	bltu	a4,a5,80005084 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005070:	8526                	mv	a0,s1
    80005072:	60a6                	ld	ra,72(sp)
    80005074:	6406                	ld	s0,64(sp)
    80005076:	74e2                	ld	s1,56(sp)
    80005078:	7942                	ld	s2,48(sp)
    8000507a:	79a2                	ld	s3,40(sp)
    8000507c:	7a02                	ld	s4,32(sp)
    8000507e:	6ae2                	ld	s5,24(sp)
    80005080:	6161                	addi	sp,sp,80
    80005082:	8082                	ret
    iunlockput(ip);
    80005084:	8526                	mv	a0,s1
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	898080e7          	jalr	-1896(ra) # 8000391e <iunlockput>
    return 0;
    8000508e:	4481                	li	s1,0
    80005090:	b7c5                	j	80005070 <create+0x72>
  if ((ip = ialloc(dp->dev, type)) == 0)
    80005092:	85ce                	mv	a1,s3
    80005094:	00092503          	lw	a0,0(s2)
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	48c080e7          	jalr	1164(ra) # 80003524 <ialloc>
    800050a0:	84aa                	mv	s1,a0
    800050a2:	c521                	beqz	a0,800050ea <create+0xec>
  ilock(ip);
    800050a4:	ffffe097          	auipc	ra,0xffffe
    800050a8:	618080e7          	jalr	1560(ra) # 800036bc <ilock>
  ip->major = major;
    800050ac:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050b0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050b4:	4a05                	li	s4,1
    800050b6:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffe097          	auipc	ra,0xffffe
    800050c0:	536080e7          	jalr	1334(ra) # 800035f2 <iupdate>
  if (type == T_DIR)
    800050c4:	2981                	sext.w	s3,s3
    800050c6:	03498a63          	beq	s3,s4,800050fa <create+0xfc>
  if (dirlink(dp, name, ip->inum) < 0)
    800050ca:	40d0                	lw	a2,4(s1)
    800050cc:	fb040593          	addi	a1,s0,-80
    800050d0:	854a                	mv	a0,s2
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	cde080e7          	jalr	-802(ra) # 80003db0 <dirlink>
    800050da:	06054b63          	bltz	a0,80005150 <create+0x152>
  iunlockput(dp);
    800050de:	854a                	mv	a0,s2
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	83e080e7          	jalr	-1986(ra) # 8000391e <iunlockput>
  return ip;
    800050e8:	b761                	j	80005070 <create+0x72>
    panic("create: ialloc");
    800050ea:	00003517          	auipc	a0,0x3
    800050ee:	68650513          	addi	a0,a0,1670 # 80008770 <syscalls+0x2a8>
    800050f2:	ffffb097          	auipc	ra,0xffffb
    800050f6:	446080e7          	jalr	1094(ra) # 80000538 <panic>
    dp->nlink++; // for ".."
    800050fa:	04a95783          	lhu	a5,74(s2)
    800050fe:	2785                	addiw	a5,a5,1
    80005100:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005104:	854a                	mv	a0,s2
    80005106:	ffffe097          	auipc	ra,0xffffe
    8000510a:	4ec080e7          	jalr	1260(ra) # 800035f2 <iupdate>
    if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000510e:	40d0                	lw	a2,4(s1)
    80005110:	00003597          	auipc	a1,0x3
    80005114:	67058593          	addi	a1,a1,1648 # 80008780 <syscalls+0x2b8>
    80005118:	8526                	mv	a0,s1
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	c96080e7          	jalr	-874(ra) # 80003db0 <dirlink>
    80005122:	00054f63          	bltz	a0,80005140 <create+0x142>
    80005126:	00492603          	lw	a2,4(s2)
    8000512a:	00003597          	auipc	a1,0x3
    8000512e:	65e58593          	addi	a1,a1,1630 # 80008788 <syscalls+0x2c0>
    80005132:	8526                	mv	a0,s1
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	c7c080e7          	jalr	-900(ra) # 80003db0 <dirlink>
    8000513c:	f80557e3          	bgez	a0,800050ca <create+0xcc>
      panic("create dots");
    80005140:	00003517          	auipc	a0,0x3
    80005144:	65050513          	addi	a0,a0,1616 # 80008790 <syscalls+0x2c8>
    80005148:	ffffb097          	auipc	ra,0xffffb
    8000514c:	3f0080e7          	jalr	1008(ra) # 80000538 <panic>
    panic("create: dirlink");
    80005150:	00003517          	auipc	a0,0x3
    80005154:	65050513          	addi	a0,a0,1616 # 800087a0 <syscalls+0x2d8>
    80005158:	ffffb097          	auipc	ra,0xffffb
    8000515c:	3e0080e7          	jalr	992(ra) # 80000538 <panic>
    return 0;
    80005160:	84aa                	mv	s1,a0
    80005162:	b739                	j	80005070 <create+0x72>

0000000080005164 <sys_dup>:
{
    80005164:	7179                	addi	sp,sp,-48
    80005166:	f406                	sd	ra,40(sp)
    80005168:	f022                	sd	s0,32(sp)
    8000516a:	ec26                	sd	s1,24(sp)
    8000516c:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0)
    8000516e:	fd840613          	addi	a2,s0,-40
    80005172:	4581                	li	a1,0
    80005174:	4501                	li	a0,0
    80005176:	00000097          	auipc	ra,0x0
    8000517a:	dde080e7          	jalr	-546(ra) # 80004f54 <argfd>
    return -1;
    8000517e:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0)
    80005180:	02054363          	bltz	a0,800051a6 <sys_dup+0x42>
  if ((fd = fdalloc(f)) < 0)
    80005184:	fd843503          	ld	a0,-40(s0)
    80005188:	00000097          	auipc	ra,0x0
    8000518c:	e34080e7          	jalr	-460(ra) # 80004fbc <fdalloc>
    80005190:	84aa                	mv	s1,a0
    return -1;
    80005192:	57fd                	li	a5,-1
  if ((fd = fdalloc(f)) < 0)
    80005194:	00054963          	bltz	a0,800051a6 <sys_dup+0x42>
  filedup(f);
    80005198:	fd843503          	ld	a0,-40(s0)
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	36c080e7          	jalr	876(ra) # 80004508 <filedup>
  return fd;
    800051a4:	87a6                	mv	a5,s1
}
    800051a6:	853e                	mv	a0,a5
    800051a8:	70a2                	ld	ra,40(sp)
    800051aa:	7402                	ld	s0,32(sp)
    800051ac:	64e2                	ld	s1,24(sp)
    800051ae:	6145                	addi	sp,sp,48
    800051b0:	8082                	ret

00000000800051b2 <sys_read>:
{
    800051b2:	7179                	addi	sp,sp,-48
    800051b4:	f406                	sd	ra,40(sp)
    800051b6:	f022                	sd	s0,32(sp)
    800051b8:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ba:	fe840613          	addi	a2,s0,-24
    800051be:	4581                	li	a1,0
    800051c0:	4501                	li	a0,0
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	d92080e7          	jalr	-622(ra) # 80004f54 <argfd>
    return -1;
    800051ca:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051cc:	04054163          	bltz	a0,8000520e <sys_read+0x5c>
    800051d0:	fe440593          	addi	a1,s0,-28
    800051d4:	4509                	li	a0,2
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	95c080e7          	jalr	-1700(ra) # 80002b32 <argint>
    return -1;
    800051de:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	02054763          	bltz	a0,8000520e <sys_read+0x5c>
    800051e4:	fd840593          	addi	a1,s0,-40
    800051e8:	4505                	li	a0,1
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	96a080e7          	jalr	-1686(ra) # 80002b54 <argaddr>
    return -1;
    800051f2:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f4:	00054d63          	bltz	a0,8000520e <sys_read+0x5c>
  return fileread(f, p, n);
    800051f8:	fe442603          	lw	a2,-28(s0)
    800051fc:	fd843583          	ld	a1,-40(s0)
    80005200:	fe843503          	ld	a0,-24(s0)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	490080e7          	jalr	1168(ra) # 80004694 <fileread>
    8000520c:	87aa                	mv	a5,a0
}
    8000520e:	853e                	mv	a0,a5
    80005210:	70a2                	ld	ra,40(sp)
    80005212:	7402                	ld	s0,32(sp)
    80005214:	6145                	addi	sp,sp,48
    80005216:	8082                	ret

0000000080005218 <sys_write>:
{
    80005218:	7179                	addi	sp,sp,-48
    8000521a:	f406                	sd	ra,40(sp)
    8000521c:	f022                	sd	s0,32(sp)
    8000521e:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005220:	fe840613          	addi	a2,s0,-24
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	d2c080e7          	jalr	-724(ra) # 80004f54 <argfd>
    return -1;
    80005230:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005232:	04054163          	bltz	a0,80005274 <sys_write+0x5c>
    80005236:	fe440593          	addi	a1,s0,-28
    8000523a:	4509                	li	a0,2
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	8f6080e7          	jalr	-1802(ra) # 80002b32 <argint>
    return -1;
    80005244:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005246:	02054763          	bltz	a0,80005274 <sys_write+0x5c>
    8000524a:	fd840593          	addi	a1,s0,-40
    8000524e:	4505                	li	a0,1
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	904080e7          	jalr	-1788(ra) # 80002b54 <argaddr>
    return -1;
    80005258:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525a:	00054d63          	bltz	a0,80005274 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000525e:	fe442603          	lw	a2,-28(s0)
    80005262:	fd843583          	ld	a1,-40(s0)
    80005266:	fe843503          	ld	a0,-24(s0)
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	4ec080e7          	jalr	1260(ra) # 80004756 <filewrite>
    80005272:	87aa                	mv	a5,a0
}
    80005274:	853e                	mv	a0,a5
    80005276:	70a2                	ld	ra,40(sp)
    80005278:	7402                	ld	s0,32(sp)
    8000527a:	6145                	addi	sp,sp,48
    8000527c:	8082                	ret

000000008000527e <sys_close>:
{
    8000527e:	1101                	addi	sp,sp,-32
    80005280:	ec06                	sd	ra,24(sp)
    80005282:	e822                	sd	s0,16(sp)
    80005284:	1000                	addi	s0,sp,32
  if (argfd(0, &fd, &f) < 0)
    80005286:	fe040613          	addi	a2,s0,-32
    8000528a:	fec40593          	addi	a1,s0,-20
    8000528e:	4501                	li	a0,0
    80005290:	00000097          	auipc	ra,0x0
    80005294:	cc4080e7          	jalr	-828(ra) # 80004f54 <argfd>
    return -1;
    80005298:	57fd                	li	a5,-1
  if (argfd(0, &fd, &f) < 0)
    8000529a:	02054463          	bltz	a0,800052c2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	6f8080e7          	jalr	1784(ra) # 80001996 <myproc>
    800052a6:	fec42783          	lw	a5,-20(s0)
    800052aa:	07e9                	addi	a5,a5,26
    800052ac:	078e                	slli	a5,a5,0x3
    800052ae:	97aa                	add	a5,a5,a0
    800052b0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052b4:	fe043503          	ld	a0,-32(s0)
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	2a2080e7          	jalr	674(ra) # 8000455a <fileclose>
  return 0;
    800052c0:	4781                	li	a5,0
}
    800052c2:	853e                	mv	a0,a5
    800052c4:	60e2                	ld	ra,24(sp)
    800052c6:	6442                	ld	s0,16(sp)
    800052c8:	6105                	addi	sp,sp,32
    800052ca:	8082                	ret

00000000800052cc <sys_fstat>:
{
    800052cc:	1101                	addi	sp,sp,-32
    800052ce:	ec06                	sd	ra,24(sp)
    800052d0:	e822                	sd	s0,16(sp)
    800052d2:	1000                	addi	s0,sp,32
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052d4:	fe840613          	addi	a2,s0,-24
    800052d8:	4581                	li	a1,0
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	c78080e7          	jalr	-904(ra) # 80004f54 <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052e6:	02054563          	bltz	a0,80005310 <sys_fstat+0x44>
    800052ea:	fe040593          	addi	a1,s0,-32
    800052ee:	4505                	li	a0,1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	864080e7          	jalr	-1948(ra) # 80002b54 <argaddr>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052fa:	00054b63          	bltz	a0,80005310 <sys_fstat+0x44>
  return filestat(f, st);
    800052fe:	fe043583          	ld	a1,-32(s0)
    80005302:	fe843503          	ld	a0,-24(s0)
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	31c080e7          	jalr	796(ra) # 80004622 <filestat>
    8000530e:	87aa                	mv	a5,a0
}
    80005310:	853e                	mv	a0,a5
    80005312:	60e2                	ld	ra,24(sp)
    80005314:	6442                	ld	s0,16(sp)
    80005316:	6105                	addi	sp,sp,32
    80005318:	8082                	ret

000000008000531a <sys_link>:
{
    8000531a:	7169                	addi	sp,sp,-304
    8000531c:	f606                	sd	ra,296(sp)
    8000531e:	f222                	sd	s0,288(sp)
    80005320:	ee26                	sd	s1,280(sp)
    80005322:	ea4a                	sd	s2,272(sp)
    80005324:	1a00                	addi	s0,sp,304
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005326:	08000613          	li	a2,128
    8000532a:	ed040593          	addi	a1,s0,-304
    8000532e:	4501                	li	a0,0
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	846080e7          	jalr	-1978(ra) # 80002b76 <argstr>
    return -1;
    80005338:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533a:	10054e63          	bltz	a0,80005456 <sys_link+0x13c>
    8000533e:	08000613          	li	a2,128
    80005342:	f5040593          	addi	a1,s0,-176
    80005346:	4505                	li	a0,1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	82e080e7          	jalr	-2002(ra) # 80002b76 <argstr>
    return -1;
    80005350:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005352:	10054263          	bltz	a0,80005456 <sys_link+0x13c>
  begin_op();
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	d38080e7          	jalr	-712(ra) # 8000408e <begin_op>
  if ((ip = namei(old)) == 0)
    8000535e:	ed040513          	addi	a0,s0,-304
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	b10080e7          	jalr	-1264(ra) # 80003e72 <namei>
    8000536a:	84aa                	mv	s1,a0
    8000536c:	c551                	beqz	a0,800053f8 <sys_link+0xde>
  ilock(ip);
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	34e080e7          	jalr	846(ra) # 800036bc <ilock>
  if (ip->type == T_DIR)
    80005376:	04449703          	lh	a4,68(s1)
    8000537a:	4785                	li	a5,1
    8000537c:	08f70463          	beq	a4,a5,80005404 <sys_link+0xea>
  ip->nlink++;
    80005380:	04a4d783          	lhu	a5,74(s1)
    80005384:	2785                	addiw	a5,a5,1
    80005386:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000538a:	8526                	mv	a0,s1
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	266080e7          	jalr	614(ra) # 800035f2 <iupdate>
  iunlock(ip);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	3e8080e7          	jalr	1000(ra) # 8000377e <iunlock>
  if ((dp = nameiparent(new, name)) == 0)
    8000539e:	fd040593          	addi	a1,s0,-48
    800053a2:	f5040513          	addi	a0,s0,-176
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	aea080e7          	jalr	-1302(ra) # 80003e90 <nameiparent>
    800053ae:	892a                	mv	s2,a0
    800053b0:	c935                	beqz	a0,80005424 <sys_link+0x10a>
  ilock(dp);
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	30a080e7          	jalr	778(ra) # 800036bc <ilock>
  if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0)
    800053ba:	00092703          	lw	a4,0(s2)
    800053be:	409c                	lw	a5,0(s1)
    800053c0:	04f71d63          	bne	a4,a5,8000541a <sys_link+0x100>
    800053c4:	40d0                	lw	a2,4(s1)
    800053c6:	fd040593          	addi	a1,s0,-48
    800053ca:	854a                	mv	a0,s2
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	9e4080e7          	jalr	-1564(ra) # 80003db0 <dirlink>
    800053d4:	04054363          	bltz	a0,8000541a <sys_link+0x100>
  iunlockput(dp);
    800053d8:	854a                	mv	a0,s2
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	544080e7          	jalr	1348(ra) # 8000391e <iunlockput>
  iput(ip);
    800053e2:	8526                	mv	a0,s1
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	492080e7          	jalr	1170(ra) # 80003876 <iput>
  end_op();
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	d22080e7          	jalr	-734(ra) # 8000410e <end_op>
  return 0;
    800053f4:	4781                	li	a5,0
    800053f6:	a085                	j	80005456 <sys_link+0x13c>
    end_op();
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	d16080e7          	jalr	-746(ra) # 8000410e <end_op>
    return -1;
    80005400:	57fd                	li	a5,-1
    80005402:	a891                	j	80005456 <sys_link+0x13c>
    iunlockput(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	518080e7          	jalr	1304(ra) # 8000391e <iunlockput>
    end_op();
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	d00080e7          	jalr	-768(ra) # 8000410e <end_op>
    return -1;
    80005416:	57fd                	li	a5,-1
    80005418:	a83d                	j	80005456 <sys_link+0x13c>
    iunlockput(dp);
    8000541a:	854a                	mv	a0,s2
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	502080e7          	jalr	1282(ra) # 8000391e <iunlockput>
  ilock(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	296080e7          	jalr	662(ra) # 800036bc <ilock>
  ip->nlink--;
    8000542e:	04a4d783          	lhu	a5,74(s1)
    80005432:	37fd                	addiw	a5,a5,-1
    80005434:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	1b8080e7          	jalr	440(ra) # 800035f2 <iupdate>
  iunlockput(ip);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	4da080e7          	jalr	1242(ra) # 8000391e <iunlockput>
  end_op();
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	cc2080e7          	jalr	-830(ra) # 8000410e <end_op>
  return -1;
    80005454:	57fd                	li	a5,-1
}
    80005456:	853e                	mv	a0,a5
    80005458:	70b2                	ld	ra,296(sp)
    8000545a:	7412                	ld	s0,288(sp)
    8000545c:	64f2                	ld	s1,280(sp)
    8000545e:	6952                	ld	s2,272(sp)
    80005460:	6155                	addi	sp,sp,304
    80005462:	8082                	ret

0000000080005464 <sys_unlink>:
{
    80005464:	7151                	addi	sp,sp,-240
    80005466:	f586                	sd	ra,232(sp)
    80005468:	f1a2                	sd	s0,224(sp)
    8000546a:	eda6                	sd	s1,216(sp)
    8000546c:	e9ca                	sd	s2,208(sp)
    8000546e:	e5ce                	sd	s3,200(sp)
    80005470:	1980                	addi	s0,sp,240
  if (argstr(0, path, MAXPATH) < 0)
    80005472:	08000613          	li	a2,128
    80005476:	f3040593          	addi	a1,s0,-208
    8000547a:	4501                	li	a0,0
    8000547c:	ffffd097          	auipc	ra,0xffffd
    80005480:	6fa080e7          	jalr	1786(ra) # 80002b76 <argstr>
    80005484:	18054163          	bltz	a0,80005606 <sys_unlink+0x1a2>
  begin_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	c06080e7          	jalr	-1018(ra) # 8000408e <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    80005490:	fb040593          	addi	a1,s0,-80
    80005494:	f3040513          	addi	a0,s0,-208
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	9f8080e7          	jalr	-1544(ra) # 80003e90 <nameiparent>
    800054a0:	84aa                	mv	s1,a0
    800054a2:	c979                	beqz	a0,80005578 <sys_unlink+0x114>
  ilock(dp);
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	218080e7          	jalr	536(ra) # 800036bc <ilock>
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ac:	00003597          	auipc	a1,0x3
    800054b0:	2d458593          	addi	a1,a1,724 # 80008780 <syscalls+0x2b8>
    800054b4:	fb040513          	addi	a0,s0,-80
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	6ce080e7          	jalr	1742(ra) # 80003b86 <namecmp>
    800054c0:	14050a63          	beqz	a0,80005614 <sys_unlink+0x1b0>
    800054c4:	00003597          	auipc	a1,0x3
    800054c8:	2c458593          	addi	a1,a1,708 # 80008788 <syscalls+0x2c0>
    800054cc:	fb040513          	addi	a0,s0,-80
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	6b6080e7          	jalr	1718(ra) # 80003b86 <namecmp>
    800054d8:	12050e63          	beqz	a0,80005614 <sys_unlink+0x1b0>
  if ((ip = dirlookup(dp, name, &off)) == 0)
    800054dc:	f2c40613          	addi	a2,s0,-212
    800054e0:	fb040593          	addi	a1,s0,-80
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	6ba080e7          	jalr	1722(ra) # 80003ba0 <dirlookup>
    800054ee:	892a                	mv	s2,a0
    800054f0:	12050263          	beqz	a0,80005614 <sys_unlink+0x1b0>
  ilock(ip);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	1c8080e7          	jalr	456(ra) # 800036bc <ilock>
  if (ip->nlink < 1)
    800054fc:	04a91783          	lh	a5,74(s2)
    80005500:	08f05263          	blez	a5,80005584 <sys_unlink+0x120>
  if (ip->type == T_DIR && !isdirempty(ip))
    80005504:	04491703          	lh	a4,68(s2)
    80005508:	4785                	li	a5,1
    8000550a:	08f70563          	beq	a4,a5,80005594 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000550e:	4641                	li	a2,16
    80005510:	4581                	li	a1,0
    80005512:	fc040513          	addi	a0,s0,-64
    80005516:	ffffb097          	auipc	ra,0xffffb
    8000551a:	7b6080e7          	jalr	1974(ra) # 80000ccc <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000551e:	4741                	li	a4,16
    80005520:	f2c42683          	lw	a3,-212(s0)
    80005524:	fc040613          	addi	a2,s0,-64
    80005528:	4581                	li	a1,0
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	53c080e7          	jalr	1340(ra) # 80003a68 <writei>
    80005534:	47c1                	li	a5,16
    80005536:	0af51563          	bne	a0,a5,800055e0 <sys_unlink+0x17c>
  if (ip->type == T_DIR)
    8000553a:	04491703          	lh	a4,68(s2)
    8000553e:	4785                	li	a5,1
    80005540:	0af70863          	beq	a4,a5,800055f0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	3d8080e7          	jalr	984(ra) # 8000391e <iunlockput>
  ip->nlink--;
    8000554e:	04a95783          	lhu	a5,74(s2)
    80005552:	37fd                	addiw	a5,a5,-1
    80005554:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005558:	854a                	mv	a0,s2
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	098080e7          	jalr	152(ra) # 800035f2 <iupdate>
  iunlockput(ip);
    80005562:	854a                	mv	a0,s2
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	3ba080e7          	jalr	954(ra) # 8000391e <iunlockput>
  end_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	ba2080e7          	jalr	-1118(ra) # 8000410e <end_op>
  return 0;
    80005574:	4501                	li	a0,0
    80005576:	a84d                	j	80005628 <sys_unlink+0x1c4>
    end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	b96080e7          	jalr	-1130(ra) # 8000410e <end_op>
    return -1;
    80005580:	557d                	li	a0,-1
    80005582:	a05d                	j	80005628 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005584:	00003517          	auipc	a0,0x3
    80005588:	22c50513          	addi	a0,a0,556 # 800087b0 <syscalls+0x2e8>
    8000558c:	ffffb097          	auipc	ra,0xffffb
    80005590:	fac080e7          	jalr	-84(ra) # 80000538 <panic>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005594:	04c92703          	lw	a4,76(s2)
    80005598:	02000793          	li	a5,32
    8000559c:	f6e7f9e3          	bgeu	a5,a4,8000550e <sys_unlink+0xaa>
    800055a0:	02000993          	li	s3,32
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055a4:	4741                	li	a4,16
    800055a6:	86ce                	mv	a3,s3
    800055a8:	f1840613          	addi	a2,s0,-232
    800055ac:	4581                	li	a1,0
    800055ae:	854a                	mv	a0,s2
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	3c0080e7          	jalr	960(ra) # 80003970 <readi>
    800055b8:	47c1                	li	a5,16
    800055ba:	00f51b63          	bne	a0,a5,800055d0 <sys_unlink+0x16c>
    if (de.inum != 0)
    800055be:	f1845783          	lhu	a5,-232(s0)
    800055c2:	e7a1                	bnez	a5,8000560a <sys_unlink+0x1a6>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    800055c4:	29c1                	addiw	s3,s3,16
    800055c6:	04c92783          	lw	a5,76(s2)
    800055ca:	fcf9ede3          	bltu	s3,a5,800055a4 <sys_unlink+0x140>
    800055ce:	b781                	j	8000550e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055d0:	00003517          	auipc	a0,0x3
    800055d4:	1f850513          	addi	a0,a0,504 # 800087c8 <syscalls+0x300>
    800055d8:	ffffb097          	auipc	ra,0xffffb
    800055dc:	f60080e7          	jalr	-160(ra) # 80000538 <panic>
    panic("unlink: writei");
    800055e0:	00003517          	auipc	a0,0x3
    800055e4:	20050513          	addi	a0,a0,512 # 800087e0 <syscalls+0x318>
    800055e8:	ffffb097          	auipc	ra,0xffffb
    800055ec:	f50080e7          	jalr	-176(ra) # 80000538 <panic>
    dp->nlink--;
    800055f0:	04a4d783          	lhu	a5,74(s1)
    800055f4:	37fd                	addiw	a5,a5,-1
    800055f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	ff6080e7          	jalr	-10(ra) # 800035f2 <iupdate>
    80005604:	b781                	j	80005544 <sys_unlink+0xe0>
    return -1;
    80005606:	557d                	li	a0,-1
    80005608:	a005                	j	80005628 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	312080e7          	jalr	786(ra) # 8000391e <iunlockput>
  iunlockput(dp);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	308080e7          	jalr	776(ra) # 8000391e <iunlockput>
  end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	af0080e7          	jalr	-1296(ra) # 8000410e <end_op>
  return -1;
    80005626:	557d                	li	a0,-1
}
    80005628:	70ae                	ld	ra,232(sp)
    8000562a:	740e                	ld	s0,224(sp)
    8000562c:	64ee                	ld	s1,216(sp)
    8000562e:	694e                	ld	s2,208(sp)
    80005630:	69ae                	ld	s3,200(sp)
    80005632:	616d                	addi	sp,sp,240
    80005634:	8082                	ret

0000000080005636 <sys_open>:

uint64
sys_open(void)
{
    80005636:	7131                	addi	sp,sp,-192
    80005638:	fd06                	sd	ra,184(sp)
    8000563a:	f922                	sd	s0,176(sp)
    8000563c:	f526                	sd	s1,168(sp)
    8000563e:	f14a                	sd	s2,160(sp)
    80005640:	ed4e                	sd	s3,152(sp)
    80005642:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if ((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005644:	08000613          	li	a2,128
    80005648:	f5040593          	addi	a1,s0,-176
    8000564c:	4501                	li	a0,0
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	528080e7          	jalr	1320(ra) # 80002b76 <argstr>
    return -1;
    80005656:	54fd                	li	s1,-1
  if ((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005658:	0c054163          	bltz	a0,8000571a <sys_open+0xe4>
    8000565c:	f4c40593          	addi	a1,s0,-180
    80005660:	4505                	li	a0,1
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	4d0080e7          	jalr	1232(ra) # 80002b32 <argint>
    8000566a:	0a054863          	bltz	a0,8000571a <sys_open+0xe4>

  begin_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	a20080e7          	jalr	-1504(ra) # 8000408e <begin_op>

  if (omode & O_CREATE)
    80005676:	f4c42783          	lw	a5,-180(s0)
    8000567a:	2007f793          	andi	a5,a5,512
    8000567e:	cbdd                	beqz	a5,80005734 <sys_open+0xfe>
  {
    ip = create(path, T_FILE, 0, 0);
    80005680:	4681                	li	a3,0
    80005682:	4601                	li	a2,0
    80005684:	4589                	li	a1,2
    80005686:	f5040513          	addi	a0,s0,-176
    8000568a:	00000097          	auipc	ra,0x0
    8000568e:	974080e7          	jalr	-1676(ra) # 80004ffe <create>
    80005692:	892a                	mv	s2,a0
    if (ip == 0)
    80005694:	c959                	beqz	a0,8000572a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if (ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV))
    80005696:	04491703          	lh	a4,68(s2)
    8000569a:	478d                	li	a5,3
    8000569c:	00f71763          	bne	a4,a5,800056aa <sys_open+0x74>
    800056a0:	04695703          	lhu	a4,70(s2)
    800056a4:	47a5                	li	a5,9
    800056a6:	0ce7ec63          	bltu	a5,a4,8000577e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if ((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	df4080e7          	jalr	-524(ra) # 8000449e <filealloc>
    800056b2:	89aa                	mv	s3,a0
    800056b4:	10050263          	beqz	a0,800057b8 <sys_open+0x182>
    800056b8:	00000097          	auipc	ra,0x0
    800056bc:	904080e7          	jalr	-1788(ra) # 80004fbc <fdalloc>
    800056c0:	84aa                	mv	s1,a0
    800056c2:	0e054663          	bltz	a0,800057ae <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if (ip->type == T_DEVICE)
    800056c6:	04491703          	lh	a4,68(s2)
    800056ca:	478d                	li	a5,3
    800056cc:	0cf70463          	beq	a4,a5,80005794 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  }
  else
  {
    f->type = FD_INODE;
    800056d0:	4789                	li	a5,2
    800056d2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056d6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056da:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056de:	f4c42783          	lw	a5,-180(s0)
    800056e2:	0017c713          	xori	a4,a5,1
    800056e6:	8b05                	andi	a4,a4,1
    800056e8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056ec:	0037f713          	andi	a4,a5,3
    800056f0:	00e03733          	snez	a4,a4
    800056f4:	00e984a3          	sb	a4,9(s3)

  if ((omode & O_TRUNC) && ip->type == T_FILE)
    800056f8:	4007f793          	andi	a5,a5,1024
    800056fc:	c791                	beqz	a5,80005708 <sys_open+0xd2>
    800056fe:	04491703          	lh	a4,68(s2)
    80005702:	4789                	li	a5,2
    80005704:	08f70f63          	beq	a4,a5,800057a2 <sys_open+0x16c>
  {
    itrunc(ip);
  }

  iunlock(ip);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	074080e7          	jalr	116(ra) # 8000377e <iunlock>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	9fc080e7          	jalr	-1540(ra) # 8000410e <end_op>

  return fd;
}
    8000571a:	8526                	mv	a0,s1
    8000571c:	70ea                	ld	ra,184(sp)
    8000571e:	744a                	ld	s0,176(sp)
    80005720:	74aa                	ld	s1,168(sp)
    80005722:	790a                	ld	s2,160(sp)
    80005724:	69ea                	ld	s3,152(sp)
    80005726:	6129                	addi	sp,sp,192
    80005728:	8082                	ret
      end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	9e4080e7          	jalr	-1564(ra) # 8000410e <end_op>
      return -1;
    80005732:	b7e5                	j	8000571a <sys_open+0xe4>
    if ((ip = namei(path)) == 0)
    80005734:	f5040513          	addi	a0,s0,-176
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	73a080e7          	jalr	1850(ra) # 80003e72 <namei>
    80005740:	892a                	mv	s2,a0
    80005742:	c905                	beqz	a0,80005772 <sys_open+0x13c>
    ilock(ip);
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	f78080e7          	jalr	-136(ra) # 800036bc <ilock>
    if (ip->type == T_DIR && omode != O_RDONLY)
    8000574c:	04491703          	lh	a4,68(s2)
    80005750:	4785                	li	a5,1
    80005752:	f4f712e3          	bne	a4,a5,80005696 <sys_open+0x60>
    80005756:	f4c42783          	lw	a5,-180(s0)
    8000575a:	dba1                	beqz	a5,800056aa <sys_open+0x74>
      iunlockput(ip);
    8000575c:	854a                	mv	a0,s2
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	1c0080e7          	jalr	448(ra) # 8000391e <iunlockput>
      end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	9a8080e7          	jalr	-1624(ra) # 8000410e <end_op>
      return -1;
    8000576e:	54fd                	li	s1,-1
    80005770:	b76d                	j	8000571a <sys_open+0xe4>
      end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	99c080e7          	jalr	-1636(ra) # 8000410e <end_op>
      return -1;
    8000577a:	54fd                	li	s1,-1
    8000577c:	bf79                	j	8000571a <sys_open+0xe4>
    iunlockput(ip);
    8000577e:	854a                	mv	a0,s2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	19e080e7          	jalr	414(ra) # 8000391e <iunlockput>
    end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	986080e7          	jalr	-1658(ra) # 8000410e <end_op>
    return -1;
    80005790:	54fd                	li	s1,-1
    80005792:	b761                	j	8000571a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005794:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005798:	04691783          	lh	a5,70(s2)
    8000579c:	02f99223          	sh	a5,36(s3)
    800057a0:	bf2d                	j	800056da <sys_open+0xa4>
    itrunc(ip);
    800057a2:	854a                	mv	a0,s2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	026080e7          	jalr	38(ra) # 800037ca <itrunc>
    800057ac:	bfb1                	j	80005708 <sys_open+0xd2>
      fileclose(f);
    800057ae:	854e                	mv	a0,s3
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	daa080e7          	jalr	-598(ra) # 8000455a <fileclose>
    iunlockput(ip);
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	164080e7          	jalr	356(ra) # 8000391e <iunlockput>
    end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	94c080e7          	jalr	-1716(ra) # 8000410e <end_op>
    return -1;
    800057ca:	54fd                	li	s1,-1
    800057cc:	b7b9                	j	8000571a <sys_open+0xe4>

00000000800057ce <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057ce:	7175                	addi	sp,sp,-144
    800057d0:	e506                	sd	ra,136(sp)
    800057d2:	e122                	sd	s0,128(sp)
    800057d4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	8b8080e7          	jalr	-1864(ra) # 8000408e <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
    800057de:	08000613          	li	a2,128
    800057e2:	f7040593          	addi	a1,s0,-144
    800057e6:	4501                	li	a0,0
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	38e080e7          	jalr	910(ra) # 80002b76 <argstr>
    800057f0:	02054963          	bltz	a0,80005822 <sys_mkdir+0x54>
    800057f4:	4681                	li	a3,0
    800057f6:	4601                	li	a2,0
    800057f8:	4585                	li	a1,1
    800057fa:	f7040513          	addi	a0,s0,-144
    800057fe:	00000097          	auipc	ra,0x0
    80005802:	800080e7          	jalr	-2048(ra) # 80004ffe <create>
    80005806:	cd11                	beqz	a0,80005822 <sys_mkdir+0x54>
  {
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	116080e7          	jalr	278(ra) # 8000391e <iunlockput>
  end_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	8fe080e7          	jalr	-1794(ra) # 8000410e <end_op>
  return 0;
    80005818:	4501                	li	a0,0
}
    8000581a:	60aa                	ld	ra,136(sp)
    8000581c:	640a                	ld	s0,128(sp)
    8000581e:	6149                	addi	sp,sp,144
    80005820:	8082                	ret
    end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	8ec080e7          	jalr	-1812(ra) # 8000410e <end_op>
    return -1;
    8000582a:	557d                	li	a0,-1
    8000582c:	b7fd                	j	8000581a <sys_mkdir+0x4c>

000000008000582e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000582e:	7135                	addi	sp,sp,-160
    80005830:	ed06                	sd	ra,152(sp)
    80005832:	e922                	sd	s0,144(sp)
    80005834:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	858080e7          	jalr	-1960(ra) # 8000408e <begin_op>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    8000583e:	08000613          	li	a2,128
    80005842:	f7040593          	addi	a1,s0,-144
    80005846:	4501                	li	a0,0
    80005848:	ffffd097          	auipc	ra,0xffffd
    8000584c:	32e080e7          	jalr	814(ra) # 80002b76 <argstr>
    80005850:	04054a63          	bltz	a0,800058a4 <sys_mknod+0x76>
      argint(1, &major) < 0 ||
    80005854:	f6c40593          	addi	a1,s0,-148
    80005858:	4505                	li	a0,1
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	2d8080e7          	jalr	728(ra) # 80002b32 <argint>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    80005862:	04054163          	bltz	a0,800058a4 <sys_mknod+0x76>
      argint(2, &minor) < 0 ||
    80005866:	f6840593          	addi	a1,s0,-152
    8000586a:	4509                	li	a0,2
    8000586c:	ffffd097          	auipc	ra,0xffffd
    80005870:	2c6080e7          	jalr	710(ra) # 80002b32 <argint>
      argint(1, &major) < 0 ||
    80005874:	02054863          	bltz	a0,800058a4 <sys_mknod+0x76>
      (ip = create(path, T_DEVICE, major, minor)) == 0)
    80005878:	f6841683          	lh	a3,-152(s0)
    8000587c:	f6c41603          	lh	a2,-148(s0)
    80005880:	458d                	li	a1,3
    80005882:	f7040513          	addi	a0,s0,-144
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	778080e7          	jalr	1912(ra) # 80004ffe <create>
      argint(2, &minor) < 0 ||
    8000588e:	c919                	beqz	a0,800058a4 <sys_mknod+0x76>
  {
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	08e080e7          	jalr	142(ra) # 8000391e <iunlockput>
  end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	876080e7          	jalr	-1930(ra) # 8000410e <end_op>
  return 0;
    800058a0:	4501                	li	a0,0
    800058a2:	a031                	j	800058ae <sys_mknod+0x80>
    end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	86a080e7          	jalr	-1942(ra) # 8000410e <end_op>
    return -1;
    800058ac:	557d                	li	a0,-1
}
    800058ae:	60ea                	ld	ra,152(sp)
    800058b0:	644a                	ld	s0,144(sp)
    800058b2:	610d                	addi	sp,sp,160
    800058b4:	8082                	ret

00000000800058b6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058b6:	7135                	addi	sp,sp,-160
    800058b8:	ed06                	sd	ra,152(sp)
    800058ba:	e922                	sd	s0,144(sp)
    800058bc:	e526                	sd	s1,136(sp)
    800058be:	e14a                	sd	s2,128(sp)
    800058c0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058c2:	ffffc097          	auipc	ra,0xffffc
    800058c6:	0d4080e7          	jalr	212(ra) # 80001996 <myproc>
    800058ca:	892a                	mv	s2,a0

  begin_op();
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	7c2080e7          	jalr	1986(ra) # 8000408e <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0)
    800058d4:	08000613          	li	a2,128
    800058d8:	f6040593          	addi	a1,s0,-160
    800058dc:	4501                	li	a0,0
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	298080e7          	jalr	664(ra) # 80002b76 <argstr>
    800058e6:	04054b63          	bltz	a0,8000593c <sys_chdir+0x86>
    800058ea:	f6040513          	addi	a0,s0,-160
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	584080e7          	jalr	1412(ra) # 80003e72 <namei>
    800058f6:	84aa                	mv	s1,a0
    800058f8:	c131                	beqz	a0,8000593c <sys_chdir+0x86>
  {
    end_op();
    return -1;
  }
  ilock(ip);
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	dc2080e7          	jalr	-574(ra) # 800036bc <ilock>
  if (ip->type != T_DIR)
    80005902:	04449703          	lh	a4,68(s1)
    80005906:	4785                	li	a5,1
    80005908:	04f71063          	bne	a4,a5,80005948 <sys_chdir+0x92>
  {
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	e70080e7          	jalr	-400(ra) # 8000377e <iunlock>
  iput(p->cwd);
    80005916:	15093503          	ld	a0,336(s2)
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	f5c080e7          	jalr	-164(ra) # 80003876 <iput>
  end_op();
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	7ec080e7          	jalr	2028(ra) # 8000410e <end_op>
  p->cwd = ip;
    8000592a:	14993823          	sd	s1,336(s2)
  return 0;
    8000592e:	4501                	li	a0,0
}
    80005930:	60ea                	ld	ra,152(sp)
    80005932:	644a                	ld	s0,144(sp)
    80005934:	64aa                	ld	s1,136(sp)
    80005936:	690a                	ld	s2,128(sp)
    80005938:	610d                	addi	sp,sp,160
    8000593a:	8082                	ret
    end_op();
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	7d2080e7          	jalr	2002(ra) # 8000410e <end_op>
    return -1;
    80005944:	557d                	li	a0,-1
    80005946:	b7ed                	j	80005930 <sys_chdir+0x7a>
    iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	fd4080e7          	jalr	-44(ra) # 8000391e <iunlockput>
    end_op();
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	7bc080e7          	jalr	1980(ra) # 8000410e <end_op>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	bfd1                	j	80005930 <sys_chdir+0x7a>

000000008000595e <sys_exec>:

uint64
sys_exec(void)
{
    8000595e:	7145                	addi	sp,sp,-464
    80005960:	e786                	sd	ra,456(sp)
    80005962:	e3a2                	sd	s0,448(sp)
    80005964:	ff26                	sd	s1,440(sp)
    80005966:	fb4a                	sd	s2,432(sp)
    80005968:	f74e                	sd	s3,424(sp)
    8000596a:	f352                	sd	s4,416(sp)
    8000596c:	ef56                	sd	s5,408(sp)
    8000596e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if (argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0)
    80005970:	08000613          	li	a2,128
    80005974:	f4040593          	addi	a1,s0,-192
    80005978:	4501                	li	a0,0
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	1fc080e7          	jalr	508(ra) # 80002b76 <argstr>
  {
    return -1;
    80005982:	597d                	li	s2,-1
  if (argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0)
    80005984:	0c054a63          	bltz	a0,80005a58 <sys_exec+0xfa>
    80005988:	e3840593          	addi	a1,s0,-456
    8000598c:	4505                	li	a0,1
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	1c6080e7          	jalr	454(ra) # 80002b54 <argaddr>
    80005996:	0c054163          	bltz	a0,80005a58 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000599a:	10000613          	li	a2,256
    8000599e:	4581                	li	a1,0
    800059a0:	e4040513          	addi	a0,s0,-448
    800059a4:	ffffb097          	auipc	ra,0xffffb
    800059a8:	328080e7          	jalr	808(ra) # 80000ccc <memset>
  for (i = 0;; i++)
  {
    if (i >= NELEM(argv))
    800059ac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059b0:	89a6                	mv	s3,s1
    800059b2:	4901                	li	s2,0
    if (i >= NELEM(argv))
    800059b4:	02000a13          	li	s4,32
    800059b8:	00090a9b          	sext.w	s5,s2
    {
      goto bad;
    }
    if (fetchaddr(uargv + sizeof(uint64) * i, (uint64 *)&uarg) < 0)
    800059bc:	00391793          	slli	a5,s2,0x3
    800059c0:	e3040593          	addi	a1,s0,-464
    800059c4:	e3843503          	ld	a0,-456(s0)
    800059c8:	953e                	add	a0,a0,a5
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	0ce080e7          	jalr	206(ra) # 80002a98 <fetchaddr>
    800059d2:	02054a63          	bltz	a0,80005a06 <sys_exec+0xa8>
    {
      goto bad;
    }
    if (uarg == 0)
    800059d6:	e3043783          	ld	a5,-464(s0)
    800059da:	c3b9                	beqz	a5,80005a20 <sys_exec+0xc2>
    {
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	104080e7          	jalr	260(ra) # 80000ae0 <kalloc>
    800059e4:	85aa                	mv	a1,a0
    800059e6:	00a9b023          	sd	a0,0(s3)
    if (argv[i] == 0)
    800059ea:	cd11                	beqz	a0,80005a06 <sys_exec+0xa8>
      goto bad;
    if (fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059ec:	6605                	lui	a2,0x1
    800059ee:	e3043503          	ld	a0,-464(s0)
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	0f8080e7          	jalr	248(ra) # 80002aea <fetchstr>
    800059fa:	00054663          	bltz	a0,80005a06 <sys_exec+0xa8>
    if (i >= NELEM(argv))
    800059fe:	0905                	addi	s2,s2,1
    80005a00:	09a1                	addi	s3,s3,8
    80005a02:	fb491be3          	bne	s2,s4,800059b8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

bad:
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a06:	10048913          	addi	s2,s1,256
    80005a0a:	6088                	ld	a0,0(s1)
    80005a0c:	c529                	beqz	a0,80005a56 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	fd6080e7          	jalr	-42(ra) # 800009e4 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a16:	04a1                	addi	s1,s1,8
    80005a18:	ff2499e3          	bne	s1,s2,80005a0a <sys_exec+0xac>
  return -1;
    80005a1c:	597d                	li	s2,-1
    80005a1e:	a82d                	j	80005a58 <sys_exec+0xfa>
      argv[i] = 0;
    80005a20:	0a8e                	slli	s5,s5,0x3
    80005a22:	fc040793          	addi	a5,s0,-64
    80005a26:	9abe                	add	s5,s5,a5
    80005a28:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a2c:	e4040593          	addi	a1,s0,-448
    80005a30:	f4040513          	addi	a0,s0,-192
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	178080e7          	jalr	376(ra) # 80004bac <exec>
    80005a3c:	892a                	mv	s2,a0
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3e:	10048993          	addi	s3,s1,256
    80005a42:	6088                	ld	a0,0(s1)
    80005a44:	c911                	beqz	a0,80005a58 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	f9e080e7          	jalr	-98(ra) # 800009e4 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a4e:	04a1                	addi	s1,s1,8
    80005a50:	ff3499e3          	bne	s1,s3,80005a42 <sys_exec+0xe4>
    80005a54:	a011                	j	80005a58 <sys_exec+0xfa>
  return -1;
    80005a56:	597d                	li	s2,-1
}
    80005a58:	854a                	mv	a0,s2
    80005a5a:	60be                	ld	ra,456(sp)
    80005a5c:	641e                	ld	s0,448(sp)
    80005a5e:	74fa                	ld	s1,440(sp)
    80005a60:	795a                	ld	s2,432(sp)
    80005a62:	79ba                	ld	s3,424(sp)
    80005a64:	7a1a                	ld	s4,416(sp)
    80005a66:	6afa                	ld	s5,408(sp)
    80005a68:	6179                	addi	sp,sp,464
    80005a6a:	8082                	ret

0000000080005a6c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a6c:	7139                	addi	sp,sp,-64
    80005a6e:	fc06                	sd	ra,56(sp)
    80005a70:	f822                	sd	s0,48(sp)
    80005a72:	f426                	sd	s1,40(sp)
    80005a74:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a76:	ffffc097          	auipc	ra,0xffffc
    80005a7a:	f20080e7          	jalr	-224(ra) # 80001996 <myproc>
    80005a7e:	84aa                	mv	s1,a0

  if (argaddr(0, &fdarray) < 0)
    80005a80:	fd840593          	addi	a1,s0,-40
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	0ce080e7          	jalr	206(ra) # 80002b54 <argaddr>
    return -1;
    80005a8e:	57fd                	li	a5,-1
  if (argaddr(0, &fdarray) < 0)
    80005a90:	0e054063          	bltz	a0,80005b70 <sys_pipe+0x104>
  if (pipealloc(&rf, &wf) < 0)
    80005a94:	fc840593          	addi	a1,s0,-56
    80005a98:	fd040513          	addi	a0,s0,-48
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	dee080e7          	jalr	-530(ra) # 8000488a <pipealloc>
    return -1;
    80005aa4:	57fd                	li	a5,-1
  if (pipealloc(&rf, &wf) < 0)
    80005aa6:	0c054563          	bltz	a0,80005b70 <sys_pipe+0x104>
  fd0 = -1;
    80005aaa:	fcf42223          	sw	a5,-60(s0)
  if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0)
    80005aae:	fd043503          	ld	a0,-48(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	50a080e7          	jalr	1290(ra) # 80004fbc <fdalloc>
    80005aba:	fca42223          	sw	a0,-60(s0)
    80005abe:	08054c63          	bltz	a0,80005b56 <sys_pipe+0xea>
    80005ac2:	fc843503          	ld	a0,-56(s0)
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	4f6080e7          	jalr	1270(ra) # 80004fbc <fdalloc>
    80005ace:	fca42023          	sw	a0,-64(s0)
    80005ad2:	06054863          	bltz	a0,80005b42 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80005ad6:	4691                	li	a3,4
    80005ad8:	fc440613          	addi	a2,s0,-60
    80005adc:	fd843583          	ld	a1,-40(s0)
    80005ae0:	68a8                	ld	a0,80(s1)
    80005ae2:	ffffc097          	auipc	ra,0xffffc
    80005ae6:	b74080e7          	jalr	-1164(ra) # 80001656 <copyout>
    80005aea:	02054063          	bltz	a0,80005b0a <sys_pipe+0x9e>
      copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0)
    80005aee:	4691                	li	a3,4
    80005af0:	fc040613          	addi	a2,s0,-64
    80005af4:	fd843583          	ld	a1,-40(s0)
    80005af8:	0591                	addi	a1,a1,4
    80005afa:	68a8                	ld	a0,80(s1)
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	b5a080e7          	jalr	-1190(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b04:	4781                	li	a5,0
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80005b06:	06055563          	bgez	a0,80005b70 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b0a:	fc442783          	lw	a5,-60(s0)
    80005b0e:	07e9                	addi	a5,a5,26
    80005b10:	078e                	slli	a5,a5,0x3
    80005b12:	97a6                	add	a5,a5,s1
    80005b14:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b18:	fc042503          	lw	a0,-64(s0)
    80005b1c:	0569                	addi	a0,a0,26
    80005b1e:	050e                	slli	a0,a0,0x3
    80005b20:	9526                	add	a0,a0,s1
    80005b22:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b26:	fd043503          	ld	a0,-48(s0)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	a30080e7          	jalr	-1488(ra) # 8000455a <fileclose>
    fileclose(wf);
    80005b32:	fc843503          	ld	a0,-56(s0)
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	a24080e7          	jalr	-1500(ra) # 8000455a <fileclose>
    return -1;
    80005b3e:	57fd                	li	a5,-1
    80005b40:	a805                	j	80005b70 <sys_pipe+0x104>
    if (fd0 >= 0)
    80005b42:	fc442783          	lw	a5,-60(s0)
    80005b46:	0007c863          	bltz	a5,80005b56 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b4a:	01a78513          	addi	a0,a5,26
    80005b4e:	050e                	slli	a0,a0,0x3
    80005b50:	9526                	add	a0,a0,s1
    80005b52:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b56:	fd043503          	ld	a0,-48(s0)
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	a00080e7          	jalr	-1536(ra) # 8000455a <fileclose>
    fileclose(wf);
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	9f4080e7          	jalr	-1548(ra) # 8000455a <fileclose>
    return -1;
    80005b6e:	57fd                	li	a5,-1
}
    80005b70:	853e                	mv	a0,a5
    80005b72:	70e2                	ld	ra,56(sp)
    80005b74:	7442                	ld	s0,48(sp)
    80005b76:	74a2                	ld	s1,40(sp)
    80005b78:	6121                	addi	sp,sp,64
    80005b7a:	8082                	ret
    80005b7c:	0000                	unimp
	...

0000000080005b80 <kernelvec>:
    80005b80:	7111                	addi	sp,sp,-256
    80005b82:	e006                	sd	ra,0(sp)
    80005b84:	e40a                	sd	sp,8(sp)
    80005b86:	e80e                	sd	gp,16(sp)
    80005b88:	ec12                	sd	tp,24(sp)
    80005b8a:	f016                	sd	t0,32(sp)
    80005b8c:	f41a                	sd	t1,40(sp)
    80005b8e:	f81e                	sd	t2,48(sp)
    80005b90:	fc22                	sd	s0,56(sp)
    80005b92:	e0a6                	sd	s1,64(sp)
    80005b94:	e4aa                	sd	a0,72(sp)
    80005b96:	e8ae                	sd	a1,80(sp)
    80005b98:	ecb2                	sd	a2,88(sp)
    80005b9a:	f0b6                	sd	a3,96(sp)
    80005b9c:	f4ba                	sd	a4,104(sp)
    80005b9e:	f8be                	sd	a5,112(sp)
    80005ba0:	fcc2                	sd	a6,120(sp)
    80005ba2:	e146                	sd	a7,128(sp)
    80005ba4:	e54a                	sd	s2,136(sp)
    80005ba6:	e94e                	sd	s3,144(sp)
    80005ba8:	ed52                	sd	s4,152(sp)
    80005baa:	f156                	sd	s5,160(sp)
    80005bac:	f55a                	sd	s6,168(sp)
    80005bae:	f95e                	sd	s7,176(sp)
    80005bb0:	fd62                	sd	s8,184(sp)
    80005bb2:	e1e6                	sd	s9,192(sp)
    80005bb4:	e5ea                	sd	s10,200(sp)
    80005bb6:	e9ee                	sd	s11,208(sp)
    80005bb8:	edf2                	sd	t3,216(sp)
    80005bba:	f1f6                	sd	t4,224(sp)
    80005bbc:	f5fa                	sd	t5,232(sp)
    80005bbe:	f9fe                	sd	t6,240(sp)
    80005bc0:	da5fc0ef          	jal	ra,80002964 <kerneltrap>
    80005bc4:	6082                	ld	ra,0(sp)
    80005bc6:	6122                	ld	sp,8(sp)
    80005bc8:	61c2                	ld	gp,16(sp)
    80005bca:	7282                	ld	t0,32(sp)
    80005bcc:	7322                	ld	t1,40(sp)
    80005bce:	73c2                	ld	t2,48(sp)
    80005bd0:	7462                	ld	s0,56(sp)
    80005bd2:	6486                	ld	s1,64(sp)
    80005bd4:	6526                	ld	a0,72(sp)
    80005bd6:	65c6                	ld	a1,80(sp)
    80005bd8:	6666                	ld	a2,88(sp)
    80005bda:	7686                	ld	a3,96(sp)
    80005bdc:	7726                	ld	a4,104(sp)
    80005bde:	77c6                	ld	a5,112(sp)
    80005be0:	7866                	ld	a6,120(sp)
    80005be2:	688a                	ld	a7,128(sp)
    80005be4:	692a                	ld	s2,136(sp)
    80005be6:	69ca                	ld	s3,144(sp)
    80005be8:	6a6a                	ld	s4,152(sp)
    80005bea:	7a8a                	ld	s5,160(sp)
    80005bec:	7b2a                	ld	s6,168(sp)
    80005bee:	7bca                	ld	s7,176(sp)
    80005bf0:	7c6a                	ld	s8,184(sp)
    80005bf2:	6c8e                	ld	s9,192(sp)
    80005bf4:	6d2e                	ld	s10,200(sp)
    80005bf6:	6dce                	ld	s11,208(sp)
    80005bf8:	6e6e                	ld	t3,216(sp)
    80005bfa:	7e8e                	ld	t4,224(sp)
    80005bfc:	7f2e                	ld	t5,232(sp)
    80005bfe:	7fce                	ld	t6,240(sp)
    80005c00:	6111                	addi	sp,sp,256
    80005c02:	10200073          	sret
    80005c06:	00000013          	nop
    80005c0a:	00000013          	nop
    80005c0e:	0001                	nop

0000000080005c10 <timervec>:
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	e10c                	sd	a1,0(a0)
    80005c16:	e510                	sd	a2,8(a0)
    80005c18:	e914                	sd	a3,16(a0)
    80005c1a:	6d0c                	ld	a1,24(a0)
    80005c1c:	7110                	ld	a2,32(a0)
    80005c1e:	6194                	ld	a3,0(a1)
    80005c20:	96b2                	add	a3,a3,a2
    80005c22:	e194                	sd	a3,0(a1)
    80005c24:	4589                	li	a1,2
    80005c26:	14459073          	csrw	sip,a1
    80005c2a:	6914                	ld	a3,16(a0)
    80005c2c:	6510                	ld	a2,8(a0)
    80005c2e:	610c                	ld	a1,0(a0)
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	30200073          	mret
	...

0000000080005c3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c3a:	1141                	addi	sp,sp,-16
    80005c3c:	e422                	sd	s0,8(sp)
    80005c3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c40:	0c0007b7          	lui	a5,0xc000
    80005c44:	4705                	li	a4,1
    80005c46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c48:	c3d8                	sw	a4,4(a5)
}
    80005c4a:	6422                	ld	s0,8(sp)
    80005c4c:	0141                	addi	sp,sp,16
    80005c4e:	8082                	ret

0000000080005c50 <plicinithart>:

void
plicinithart(void)
{
    80005c50:	1141                	addi	sp,sp,-16
    80005c52:	e406                	sd	ra,8(sp)
    80005c54:	e022                	sd	s0,0(sp)
    80005c56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d12080e7          	jalr	-750(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c60:	0085171b          	slliw	a4,a0,0x8
    80005c64:	0c0027b7          	lui	a5,0xc002
    80005c68:	97ba                	add	a5,a5,a4
    80005c6a:	40200713          	li	a4,1026
    80005c6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c72:	00d5151b          	slliw	a0,a0,0xd
    80005c76:	0c2017b7          	lui	a5,0xc201
    80005c7a:	953e                	add	a0,a0,a5
    80005c7c:	00052023          	sw	zero,0(a0)
}
    80005c80:	60a2                	ld	ra,8(sp)
    80005c82:	6402                	ld	s0,0(sp)
    80005c84:	0141                	addi	sp,sp,16
    80005c86:	8082                	ret

0000000080005c88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c88:	1141                	addi	sp,sp,-16
    80005c8a:	e406                	sd	ra,8(sp)
    80005c8c:	e022                	sd	s0,0(sp)
    80005c8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	cda080e7          	jalr	-806(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c98:	00d5179b          	slliw	a5,a0,0xd
    80005c9c:	0c201537          	lui	a0,0xc201
    80005ca0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ca2:	4148                	lw	a0,4(a0)
    80005ca4:	60a2                	ld	ra,8(sp)
    80005ca6:	6402                	ld	s0,0(sp)
    80005ca8:	0141                	addi	sp,sp,16
    80005caa:	8082                	ret

0000000080005cac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cac:	1101                	addi	sp,sp,-32
    80005cae:	ec06                	sd	ra,24(sp)
    80005cb0:	e822                	sd	s0,16(sp)
    80005cb2:	e426                	sd	s1,8(sp)
    80005cb4:	1000                	addi	s0,sp,32
    80005cb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	cb2080e7          	jalr	-846(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cc0:	00d5151b          	slliw	a0,a0,0xd
    80005cc4:	0c2017b7          	lui	a5,0xc201
    80005cc8:	97aa                	add	a5,a5,a0
    80005cca:	c3c4                	sw	s1,4(a5)
}
    80005ccc:	60e2                	ld	ra,24(sp)
    80005cce:	6442                	ld	s0,16(sp)
    80005cd0:	64a2                	ld	s1,8(sp)
    80005cd2:	6105                	addi	sp,sp,32
    80005cd4:	8082                	ret

0000000080005cd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cd6:	1141                	addi	sp,sp,-16
    80005cd8:	e406                	sd	ra,8(sp)
    80005cda:	e022                	sd	s0,0(sp)
    80005cdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cde:	479d                	li	a5,7
    80005ce0:	06a7c963          	blt	a5,a0,80005d52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ce4:	0001d797          	auipc	a5,0x1d
    80005ce8:	31c78793          	addi	a5,a5,796 # 80023000 <disk>
    80005cec:	00a78733          	add	a4,a5,a0
    80005cf0:	6789                	lui	a5,0x2
    80005cf2:	97ba                	add	a5,a5,a4
    80005cf4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cf8:	e7ad                	bnez	a5,80005d62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cfa:	00451793          	slli	a5,a0,0x4
    80005cfe:	0001f717          	auipc	a4,0x1f
    80005d02:	30270713          	addi	a4,a4,770 # 80025000 <disk+0x2000>
    80005d06:	6314                	ld	a3,0(a4)
    80005d08:	96be                	add	a3,a3,a5
    80005d0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d0e:	6314                	ld	a3,0(a4)
    80005d10:	96be                	add	a3,a3,a5
    80005d12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d16:	6314                	ld	a3,0(a4)
    80005d18:	96be                	add	a3,a3,a5
    80005d1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d1e:	6318                	ld	a4,0(a4)
    80005d20:	97ba                	add	a5,a5,a4
    80005d22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d26:	0001d797          	auipc	a5,0x1d
    80005d2a:	2da78793          	addi	a5,a5,730 # 80023000 <disk>
    80005d2e:	97aa                	add	a5,a5,a0
    80005d30:	6509                	lui	a0,0x2
    80005d32:	953e                	add	a0,a0,a5
    80005d34:	4785                	li	a5,1
    80005d36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d3a:	0001f517          	auipc	a0,0x1f
    80005d3e:	2de50513          	addi	a0,a0,734 # 80025018 <disk+0x2018>
    80005d42:	ffffc097          	auipc	ra,0xffffc
    80005d46:	4a0080e7          	jalr	1184(ra) # 800021e2 <wakeup>
}
    80005d4a:	60a2                	ld	ra,8(sp)
    80005d4c:	6402                	ld	s0,0(sp)
    80005d4e:	0141                	addi	sp,sp,16
    80005d50:	8082                	ret
    panic("free_desc 1");
    80005d52:	00003517          	auipc	a0,0x3
    80005d56:	a9e50513          	addi	a0,a0,-1378 # 800087f0 <syscalls+0x328>
    80005d5a:	ffffa097          	auipc	ra,0xffffa
    80005d5e:	7de080e7          	jalr	2014(ra) # 80000538 <panic>
    panic("free_desc 2");
    80005d62:	00003517          	auipc	a0,0x3
    80005d66:	a9e50513          	addi	a0,a0,-1378 # 80008800 <syscalls+0x338>
    80005d6a:	ffffa097          	auipc	ra,0xffffa
    80005d6e:	7ce080e7          	jalr	1998(ra) # 80000538 <panic>

0000000080005d72 <virtio_disk_init>:
{
    80005d72:	1101                	addi	sp,sp,-32
    80005d74:	ec06                	sd	ra,24(sp)
    80005d76:	e822                	sd	s0,16(sp)
    80005d78:	e426                	sd	s1,8(sp)
    80005d7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d7c:	00003597          	auipc	a1,0x3
    80005d80:	a9458593          	addi	a1,a1,-1388 # 80008810 <syscalls+0x348>
    80005d84:	0001f517          	auipc	a0,0x1f
    80005d88:	3a450513          	addi	a0,a0,932 # 80025128 <disk+0x2128>
    80005d8c:	ffffb097          	auipc	ra,0xffffb
    80005d90:	db4080e7          	jalr	-588(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d94:	100017b7          	lui	a5,0x10001
    80005d98:	4398                	lw	a4,0(a5)
    80005d9a:	2701                	sext.w	a4,a4
    80005d9c:	747277b7          	lui	a5,0x74727
    80005da0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005da4:	0ef71163          	bne	a4,a5,80005e86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005da8:	100017b7          	lui	a5,0x10001
    80005dac:	43dc                	lw	a5,4(a5)
    80005dae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db0:	4705                	li	a4,1
    80005db2:	0ce79a63          	bne	a5,a4,80005e86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005db6:	100017b7          	lui	a5,0x10001
    80005dba:	479c                	lw	a5,8(a5)
    80005dbc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dbe:	4709                	li	a4,2
    80005dc0:	0ce79363          	bne	a5,a4,80005e86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dc4:	100017b7          	lui	a5,0x10001
    80005dc8:	47d8                	lw	a4,12(a5)
    80005dca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dcc:	554d47b7          	lui	a5,0x554d4
    80005dd0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dd4:	0af71963          	bne	a4,a5,80005e86 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dd8:	100017b7          	lui	a5,0x10001
    80005ddc:	4705                	li	a4,1
    80005dde:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005de0:	470d                	li	a4,3
    80005de2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005de4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005de6:	c7ffe737          	lui	a4,0xc7ffe
    80005dea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005df0:	2701                	sext.w	a4,a4
    80005df2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df4:	472d                	li	a4,11
    80005df6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df8:	473d                	li	a4,15
    80005dfa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dfc:	6705                	lui	a4,0x1
    80005dfe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e04:	5bdc                	lw	a5,52(a5)
    80005e06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e08:	c7d9                	beqz	a5,80005e96 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e0a:	471d                	li	a4,7
    80005e0c:	08f77d63          	bgeu	a4,a5,80005ea6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e10:	100014b7          	lui	s1,0x10001
    80005e14:	47a1                	li	a5,8
    80005e16:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e18:	6609                	lui	a2,0x2
    80005e1a:	4581                	li	a1,0
    80005e1c:	0001d517          	auipc	a0,0x1d
    80005e20:	1e450513          	addi	a0,a0,484 # 80023000 <disk>
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	ea8080e7          	jalr	-344(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e2c:	0001d717          	auipc	a4,0x1d
    80005e30:	1d470713          	addi	a4,a4,468 # 80023000 <disk>
    80005e34:	00c75793          	srli	a5,a4,0xc
    80005e38:	2781                	sext.w	a5,a5
    80005e3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e3c:	0001f797          	auipc	a5,0x1f
    80005e40:	1c478793          	addi	a5,a5,452 # 80025000 <disk+0x2000>
    80005e44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e46:	0001d717          	auipc	a4,0x1d
    80005e4a:	23a70713          	addi	a4,a4,570 # 80023080 <disk+0x80>
    80005e4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e50:	0001e717          	auipc	a4,0x1e
    80005e54:	1b070713          	addi	a4,a4,432 # 80024000 <disk+0x1000>
    80005e58:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e5a:	4705                	li	a4,1
    80005e5c:	00e78c23          	sb	a4,24(a5)
    80005e60:	00e78ca3          	sb	a4,25(a5)
    80005e64:	00e78d23          	sb	a4,26(a5)
    80005e68:	00e78da3          	sb	a4,27(a5)
    80005e6c:	00e78e23          	sb	a4,28(a5)
    80005e70:	00e78ea3          	sb	a4,29(a5)
    80005e74:	00e78f23          	sb	a4,30(a5)
    80005e78:	00e78fa3          	sb	a4,31(a5)
}
    80005e7c:	60e2                	ld	ra,24(sp)
    80005e7e:	6442                	ld	s0,16(sp)
    80005e80:	64a2                	ld	s1,8(sp)
    80005e82:	6105                	addi	sp,sp,32
    80005e84:	8082                	ret
    panic("could not find virtio disk");
    80005e86:	00003517          	auipc	a0,0x3
    80005e8a:	99a50513          	addi	a0,a0,-1638 # 80008820 <syscalls+0x358>
    80005e8e:	ffffa097          	auipc	ra,0xffffa
    80005e92:	6aa080e7          	jalr	1706(ra) # 80000538 <panic>
    panic("virtio disk has no queue 0");
    80005e96:	00003517          	auipc	a0,0x3
    80005e9a:	9aa50513          	addi	a0,a0,-1622 # 80008840 <syscalls+0x378>
    80005e9e:	ffffa097          	auipc	ra,0xffffa
    80005ea2:	69a080e7          	jalr	1690(ra) # 80000538 <panic>
    panic("virtio disk max queue too short");
    80005ea6:	00003517          	auipc	a0,0x3
    80005eaa:	9ba50513          	addi	a0,a0,-1606 # 80008860 <syscalls+0x398>
    80005eae:	ffffa097          	auipc	ra,0xffffa
    80005eb2:	68a080e7          	jalr	1674(ra) # 80000538 <panic>

0000000080005eb6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005eb6:	7119                	addi	sp,sp,-128
    80005eb8:	fc86                	sd	ra,120(sp)
    80005eba:	f8a2                	sd	s0,112(sp)
    80005ebc:	f4a6                	sd	s1,104(sp)
    80005ebe:	f0ca                	sd	s2,96(sp)
    80005ec0:	ecce                	sd	s3,88(sp)
    80005ec2:	e8d2                	sd	s4,80(sp)
    80005ec4:	e4d6                	sd	s5,72(sp)
    80005ec6:	e0da                	sd	s6,64(sp)
    80005ec8:	fc5e                	sd	s7,56(sp)
    80005eca:	f862                	sd	s8,48(sp)
    80005ecc:	f466                	sd	s9,40(sp)
    80005ece:	f06a                	sd	s10,32(sp)
    80005ed0:	ec6e                	sd	s11,24(sp)
    80005ed2:	0100                	addi	s0,sp,128
    80005ed4:	8aaa                	mv	s5,a0
    80005ed6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ed8:	00c52c83          	lw	s9,12(a0)
    80005edc:	001c9c9b          	slliw	s9,s9,0x1
    80005ee0:	1c82                	slli	s9,s9,0x20
    80005ee2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ee6:	0001f517          	auipc	a0,0x1f
    80005eea:	24250513          	addi	a0,a0,578 # 80025128 <disk+0x2128>
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	ce2080e7          	jalr	-798(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005ef6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ef8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005efa:	0001dc17          	auipc	s8,0x1d
    80005efe:	106c0c13          	addi	s8,s8,262 # 80023000 <disk>
    80005f02:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f04:	4b0d                	li	s6,3
    80005f06:	a0ad                	j	80005f70 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f08:	00fc0733          	add	a4,s8,a5
    80005f0c:	975e                	add	a4,a4,s7
    80005f0e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f12:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f14:	0207c563          	bltz	a5,80005f3e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f18:	2905                	addiw	s2,s2,1
    80005f1a:	0611                	addi	a2,a2,4
    80005f1c:	19690d63          	beq	s2,s6,800060b6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f20:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f22:	0001f717          	auipc	a4,0x1f
    80005f26:	0f670713          	addi	a4,a4,246 # 80025018 <disk+0x2018>
    80005f2a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f2c:	00074683          	lbu	a3,0(a4)
    80005f30:	fee1                	bnez	a3,80005f08 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f32:	2785                	addiw	a5,a5,1
    80005f34:	0705                	addi	a4,a4,1
    80005f36:	fe979be3          	bne	a5,s1,80005f2c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f3a:	57fd                	li	a5,-1
    80005f3c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f3e:	01205d63          	blez	s2,80005f58 <virtio_disk_rw+0xa2>
    80005f42:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f44:	000a2503          	lw	a0,0(s4)
    80005f48:	00000097          	auipc	ra,0x0
    80005f4c:	d8e080e7          	jalr	-626(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f50:	2d85                	addiw	s11,s11,1
    80005f52:	0a11                	addi	s4,s4,4
    80005f54:	ffb918e3          	bne	s2,s11,80005f44 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f58:	0001f597          	auipc	a1,0x1f
    80005f5c:	1d058593          	addi	a1,a1,464 # 80025128 <disk+0x2128>
    80005f60:	0001f517          	auipc	a0,0x1f
    80005f64:	0b850513          	addi	a0,a0,184 # 80025018 <disk+0x2018>
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	0ee080e7          	jalr	238(ra) # 80002056 <sleep>
  for(int i = 0; i < 3; i++){
    80005f70:	f8040a13          	addi	s4,s0,-128
{
    80005f74:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f76:	894e                	mv	s2,s3
    80005f78:	b765                	j	80005f20 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f7a:	0001f697          	auipc	a3,0x1f
    80005f7e:	0866b683          	ld	a3,134(a3) # 80025000 <disk+0x2000>
    80005f82:	96ba                	add	a3,a3,a4
    80005f84:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f88:	0001d817          	auipc	a6,0x1d
    80005f8c:	07880813          	addi	a6,a6,120 # 80023000 <disk>
    80005f90:	0001f697          	auipc	a3,0x1f
    80005f94:	07068693          	addi	a3,a3,112 # 80025000 <disk+0x2000>
    80005f98:	6290                	ld	a2,0(a3)
    80005f9a:	963a                	add	a2,a2,a4
    80005f9c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005fa0:	0015e593          	ori	a1,a1,1
    80005fa4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fa8:	f8842603          	lw	a2,-120(s0)
    80005fac:	628c                	ld	a1,0(a3)
    80005fae:	972e                	add	a4,a4,a1
    80005fb0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fb4:	20050593          	addi	a1,a0,512
    80005fb8:	0592                	slli	a1,a1,0x4
    80005fba:	95c2                	add	a1,a1,a6
    80005fbc:	577d                	li	a4,-1
    80005fbe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fc2:	00461713          	slli	a4,a2,0x4
    80005fc6:	6290                	ld	a2,0(a3)
    80005fc8:	963a                	add	a2,a2,a4
    80005fca:	03078793          	addi	a5,a5,48
    80005fce:	97c2                	add	a5,a5,a6
    80005fd0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005fd2:	629c                	ld	a5,0(a3)
    80005fd4:	97ba                	add	a5,a5,a4
    80005fd6:	4605                	li	a2,1
    80005fd8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fda:	629c                	ld	a5,0(a3)
    80005fdc:	97ba                	add	a5,a5,a4
    80005fde:	4809                	li	a6,2
    80005fe0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005fe4:	629c                	ld	a5,0(a3)
    80005fe6:	973e                	add	a4,a4,a5
    80005fe8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fec:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005ff0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005ff4:	6698                	ld	a4,8(a3)
    80005ff6:	00275783          	lhu	a5,2(a4)
    80005ffa:	8b9d                	andi	a5,a5,7
    80005ffc:	0786                	slli	a5,a5,0x1
    80005ffe:	97ba                	add	a5,a5,a4
    80006000:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006004:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006008:	6698                	ld	a4,8(a3)
    8000600a:	00275783          	lhu	a5,2(a4)
    8000600e:	2785                	addiw	a5,a5,1
    80006010:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006014:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006020:	004aa783          	lw	a5,4(s5)
    80006024:	02c79163          	bne	a5,a2,80006046 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006028:	0001f917          	auipc	s2,0x1f
    8000602c:	10090913          	addi	s2,s2,256 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006030:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006032:	85ca                	mv	a1,s2
    80006034:	8556                	mv	a0,s5
    80006036:	ffffc097          	auipc	ra,0xffffc
    8000603a:	020080e7          	jalr	32(ra) # 80002056 <sleep>
  while(b->disk == 1) {
    8000603e:	004aa783          	lw	a5,4(s5)
    80006042:	fe9788e3          	beq	a5,s1,80006032 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006046:	f8042903          	lw	s2,-128(s0)
    8000604a:	20090793          	addi	a5,s2,512
    8000604e:	00479713          	slli	a4,a5,0x4
    80006052:	0001d797          	auipc	a5,0x1d
    80006056:	fae78793          	addi	a5,a5,-82 # 80023000 <disk>
    8000605a:	97ba                	add	a5,a5,a4
    8000605c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006060:	0001f997          	auipc	s3,0x1f
    80006064:	fa098993          	addi	s3,s3,-96 # 80025000 <disk+0x2000>
    80006068:	00491713          	slli	a4,s2,0x4
    8000606c:	0009b783          	ld	a5,0(s3)
    80006070:	97ba                	add	a5,a5,a4
    80006072:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006076:	854a                	mv	a0,s2
    80006078:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000607c:	00000097          	auipc	ra,0x0
    80006080:	c5a080e7          	jalr	-934(ra) # 80005cd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006084:	8885                	andi	s1,s1,1
    80006086:	f0ed                	bnez	s1,80006068 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006088:	0001f517          	auipc	a0,0x1f
    8000608c:	0a050513          	addi	a0,a0,160 # 80025128 <disk+0x2128>
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	bf4080e7          	jalr	-1036(ra) # 80000c84 <release>
}
    80006098:	70e6                	ld	ra,120(sp)
    8000609a:	7446                	ld	s0,112(sp)
    8000609c:	74a6                	ld	s1,104(sp)
    8000609e:	7906                	ld	s2,96(sp)
    800060a0:	69e6                	ld	s3,88(sp)
    800060a2:	6a46                	ld	s4,80(sp)
    800060a4:	6aa6                	ld	s5,72(sp)
    800060a6:	6b06                	ld	s6,64(sp)
    800060a8:	7be2                	ld	s7,56(sp)
    800060aa:	7c42                	ld	s8,48(sp)
    800060ac:	7ca2                	ld	s9,40(sp)
    800060ae:	7d02                	ld	s10,32(sp)
    800060b0:	6de2                	ld	s11,24(sp)
    800060b2:	6109                	addi	sp,sp,128
    800060b4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060b6:	f8042503          	lw	a0,-128(s0)
    800060ba:	20050793          	addi	a5,a0,512
    800060be:	0792                	slli	a5,a5,0x4
  if(write)
    800060c0:	0001d817          	auipc	a6,0x1d
    800060c4:	f4080813          	addi	a6,a6,-192 # 80023000 <disk>
    800060c8:	00f80733          	add	a4,a6,a5
    800060cc:	01a036b3          	snez	a3,s10
    800060d0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800060d4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060d8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060dc:	7679                	lui	a2,0xffffe
    800060de:	963e                	add	a2,a2,a5
    800060e0:	0001f697          	auipc	a3,0x1f
    800060e4:	f2068693          	addi	a3,a3,-224 # 80025000 <disk+0x2000>
    800060e8:	6298                	ld	a4,0(a3)
    800060ea:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060ec:	0a878593          	addi	a1,a5,168
    800060f0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060f2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060f4:	6298                	ld	a4,0(a3)
    800060f6:	9732                	add	a4,a4,a2
    800060f8:	45c1                	li	a1,16
    800060fa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060fc:	6298                	ld	a4,0(a3)
    800060fe:	9732                	add	a4,a4,a2
    80006100:	4585                	li	a1,1
    80006102:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006106:	f8442703          	lw	a4,-124(s0)
    8000610a:	628c                	ld	a1,0(a3)
    8000610c:	962e                	add	a2,a2,a1
    8000610e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006112:	0712                	slli	a4,a4,0x4
    80006114:	6290                	ld	a2,0(a3)
    80006116:	963a                	add	a2,a2,a4
    80006118:	058a8593          	addi	a1,s5,88
    8000611c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000611e:	6294                	ld	a3,0(a3)
    80006120:	96ba                	add	a3,a3,a4
    80006122:	40000613          	li	a2,1024
    80006126:	c690                	sw	a2,8(a3)
  if(write)
    80006128:	e40d19e3          	bnez	s10,80005f7a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000612c:	0001f697          	auipc	a3,0x1f
    80006130:	ed46b683          	ld	a3,-300(a3) # 80025000 <disk+0x2000>
    80006134:	96ba                	add	a3,a3,a4
    80006136:	4609                	li	a2,2
    80006138:	00c69623          	sh	a2,12(a3)
    8000613c:	b5b1                	j	80005f88 <virtio_disk_rw+0xd2>

000000008000613e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000613e:	1101                	addi	sp,sp,-32
    80006140:	ec06                	sd	ra,24(sp)
    80006142:	e822                	sd	s0,16(sp)
    80006144:	e426                	sd	s1,8(sp)
    80006146:	e04a                	sd	s2,0(sp)
    80006148:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000614a:	0001f517          	auipc	a0,0x1f
    8000614e:	fde50513          	addi	a0,a0,-34 # 80025128 <disk+0x2128>
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	a7e080e7          	jalr	-1410(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000615a:	10001737          	lui	a4,0x10001
    8000615e:	533c                	lw	a5,96(a4)
    80006160:	8b8d                	andi	a5,a5,3
    80006162:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006164:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006168:	0001f797          	auipc	a5,0x1f
    8000616c:	e9878793          	addi	a5,a5,-360 # 80025000 <disk+0x2000>
    80006170:	6b94                	ld	a3,16(a5)
    80006172:	0207d703          	lhu	a4,32(a5)
    80006176:	0026d783          	lhu	a5,2(a3)
    8000617a:	06f70163          	beq	a4,a5,800061dc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000617e:	0001d917          	auipc	s2,0x1d
    80006182:	e8290913          	addi	s2,s2,-382 # 80023000 <disk>
    80006186:	0001f497          	auipc	s1,0x1f
    8000618a:	e7a48493          	addi	s1,s1,-390 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000618e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006192:	6898                	ld	a4,16(s1)
    80006194:	0204d783          	lhu	a5,32(s1)
    80006198:	8b9d                	andi	a5,a5,7
    8000619a:	078e                	slli	a5,a5,0x3
    8000619c:	97ba                	add	a5,a5,a4
    8000619e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061a0:	20078713          	addi	a4,a5,512
    800061a4:	0712                	slli	a4,a4,0x4
    800061a6:	974a                	add	a4,a4,s2
    800061a8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061ac:	e731                	bnez	a4,800061f8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061ae:	20078793          	addi	a5,a5,512
    800061b2:	0792                	slli	a5,a5,0x4
    800061b4:	97ca                	add	a5,a5,s2
    800061b6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061b8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061bc:	ffffc097          	auipc	ra,0xffffc
    800061c0:	026080e7          	jalr	38(ra) # 800021e2 <wakeup>

    disk.used_idx += 1;
    800061c4:	0204d783          	lhu	a5,32(s1)
    800061c8:	2785                	addiw	a5,a5,1
    800061ca:	17c2                	slli	a5,a5,0x30
    800061cc:	93c1                	srli	a5,a5,0x30
    800061ce:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061d2:	6898                	ld	a4,16(s1)
    800061d4:	00275703          	lhu	a4,2(a4)
    800061d8:	faf71be3          	bne	a4,a5,8000618e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061dc:	0001f517          	auipc	a0,0x1f
    800061e0:	f4c50513          	addi	a0,a0,-180 # 80025128 <disk+0x2128>
    800061e4:	ffffb097          	auipc	ra,0xffffb
    800061e8:	aa0080e7          	jalr	-1376(ra) # 80000c84 <release>
}
    800061ec:	60e2                	ld	ra,24(sp)
    800061ee:	6442                	ld	s0,16(sp)
    800061f0:	64a2                	ld	s1,8(sp)
    800061f2:	6902                	ld	s2,0(sp)
    800061f4:	6105                	addi	sp,sp,32
    800061f6:	8082                	ret
      panic("virtio_disk_intr status");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	68850513          	addi	a0,a0,1672 # 80008880 <syscalls+0x3b8>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	338080e7          	jalr	824(ra) # 80000538 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
