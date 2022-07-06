*
*
*
	.include IOCSCALL.MAC
	.include DOSCALL.MAC

	.include SYSpatch.MAC

	.cpu	68030


	.offset	0
CRC_WORK:	ds.l	256
ttreg:		ds.l	2	* TT Regs.
tia:		ds.l	1
tib:		ds.l	1
tic:		ds.l	1
m_f:		ds.b	1	* option flags
s_f:		ds.b	1
w_f:		ds.b	1
v_f:		ds.b	1
c_f:		ds.b	1
x_f:		ds.b	1
n_f:		ds.b	1
z_f:		ds.b	1
q_f:		ds.b	1
mapbuf:		ds.b	(PMEM_MAX/PAGE_SIZE)
getbuf:		ds.b	256	* 環境変数取り込みバッファ
	.even
BSS_SIZE:
	.text


_3_SYSVER	equ	$8000
_3_CASTAT	equ	$8001
*		equ	$8002
*		equ	$8003
_3_CAMODE	equ	$8004

_3_ADDRCNV	equ	$F000
_3_MMAP		equ	$F001
_3_MSTAT	equ	$F002

X030	macro	name
	move.w	#name,d1
	moveq	#$ac,d0
	trap	#15
	endm

	.text

*----------------------------------------------------------
* タイトルの表示
*----------------------------------------------------------
@@:		dc.b	'Memory management status display v1.40 for 030SYSpatch.x'
		dc.b	13,10,0
	.even
print_title:	tst.b	(q_f,a6)
		bne	9f
		pea	(@b,pc)
		DOS	_PRINT
		addq.l	#4,sp
9:		rts

*----------------------------------------------------------
* 表示終了
*----------------------------------------------------------
no_030_msg:	dc.b	'030SYSpatch v0.40以降で使用してください',13,10,0
usage_msg:	dc.b	'使用法：mmsd [switch]',13,10
		dc.b	9,'z .... 環境変数 mmsd の無視',13,10
		dc.b	9,'q .... タイトル非表示',13,10
		dc.b	9,'a .... 全表示',13,10
		dc.b	9,'m .... マッピング',13,10
		dc.b	9,'s .... スーパーバイザ',13,10
		dc.b	9,'w .... ライトプロテクト',13,10
		dc.b	9,'c .... キャッシュモード',13,10
		dc.b	9,'v .... パッチバージョン',13,10
		dc.b	9,'x .... 透過変換レジスタ',13,10
		dc.b	9,'n .... 論理不可視領域',13,10
		dc.b	10
		dc.b	9,'環境変数 mmsd の内容がコマンドラインの最後に追加されます',13,10
		dc.b	0
	.even
no_030:		pea	(no_030_msg,pc)
		bra	@f
usage:		pea	(usage_msg,pc)
@@:		DOS	_PRINT
		addq.l	#4,sp
		DOS	_EXIT

*----------------------------------------------------------
* 設定の初期化
*----------------------------------------------------------
initialize:	lea	(bss_top,pc),a6
		move.w	#PAGE_SIZE,d6
		move.l	#PMEM_MAX,d5
		sf	(m_f,a6)
		sf	(s_f,a6)
		sf	(v_f,a6)
		sf	(w_f,a6)
		sf	(c_f,a6)
		sf	(x_f,a6)
		sf	(n_f,a6)
		sf	(z_f,a6)
		sf	(q_f,a6)
		lea	(mapbuf,a6),a5
		move.l	d5,d0
		divu.w	d6,d0		***
		subq.w	#1,d0
@@:		clr.b	(a5)+
		dbra	d0,@b
		rts

*----------------------------------------------------------
* 復改する
*----------------------------------------------------------
@@:		dc.b	13,10,0
	.even
crlf:		pea	(@b,pc)
		DOS	_PRINT
		addq.l	#4,sp
		rts

*----------------------------------------------------------
* MMU情報を得る
*----------------------------------------------------------
getmmus:	movem.l	d1/a1,-(sp)
		suba.l	a1,a1
		IOCS	_B_SUPER
		movea.l	d0,a1
		
		subq.l	#8,sp
		pmove.q	SRP,(sp)
		addq.l	#4,sp
		move.l	(sp)+,(tia,a6)
		
		ptestw	#1,($0),#2,a0			* get TIB address
		move.l	a0,(tib,a6)
		ptestw	#1,($0),#3,a0			* get TIC address
		move.l	a0,(tic,a6)
		
		IOCS	_B_SUPER
		movem.l	(sp)+,d1/a1
		rts

*----------------------------------------------------------
* バイナリ値→１６進数８桁変換
*  d0=変換するバイナリ値
*  a0=１６進数８桁を格納する番地
*----------------------------------------------------------
bin2hex:	movem.l	d1/d2/a0,-(sp)
		
		moveq	#8-1,d1
@@:		bfextu	d0{0:4},d2
		rol.l	#4,d0
		move.b	(@f,pc,d2.w),(a0)+
		dbra	d1,@b
		
		movem.l	(sp)+,d1/d2/a0
		rts
@@:		dc.b	'0123456789ABCDEF'

*------------------------------------------------------------
* CRC-32 を計算する
* in	A1 : アドレス
*	D1 : 長さ
* out	D0 : 計算結果
*------------------------------------------------------------
crc_calc:	movem.l	d1-d5/a0-a1,-(sp)
		lea	(CRC_WORK,a6),a0
		move.l	#$EDB88320,d5
		move.w	#256-1,d2
1:		move.l	d2,d4
		moveq	#8-1,d0
2:		move.b	d4,d3
		lsr.l	#1,d4
		bcc	@f
		eor.l	d5,d4
@@:		dbra	d0,2b
		move.l	d4,(a0,d2.w*4)
		dbra	d2,1b

		moveq	#-1,d0
		clr.w	d4
@@:		move.b	(a1)+,d4
		eor.b	d0,d4
		move.l	(a0,d4.w*4),d3
		lsr.l	#8,d0
		eor.l	d3,d0
		subq.l	#1,d1
		bne	@b
		not.l	d0
		movem.l	(sp)+,d1-d5/a0-a1
		rts

*----------------------------------------------------------
* 横線表示
*----------------------------------------------------------
pline:		move.l	d1,-(sp)
		moveq	#68-1,d1
		move.w	#'-',-(sp)
@@:		DOS	_PUTCHAR
		dbra	d1,@b
		addq.l	#2,sp
		bsr	crlf
		move.l	(sp)+,d1
		rts

*----------------------------------------------------------
* 使い方を表示するかどーか検査
*----------------------------------------------------------
chk_cmd:	move.b	(m_f,a6),d0
		or.b	(s_f,a6),d0
		or.b	(v_f,a6),d0
		or.b	(w_f,a6),d0
		or.b	(c_f,a6),d0
		or.b	(x_f,a6),d0
		or.b	(n_f,a6),d0
		beq	usage
		rts

*----------------------------------------------------------
* 環境変数からオプションの取得
*----------------------------------------------------------
envname:	dc.b	'mmsd',0
	.even
getenv_option:	tst.b	(z_f,a6)
		bne	9f

		lea	(getbuf,a6),a2
		pea	(1,a2)
		clr.l	-(sp)
		pea	(envname,pc)
		DOS	_GETENV
		lea	(12,sp),sp
		tst.l	d0
		bmi	9f
		moveq	#0-1,d0
@@:		addq.l	#1,d0
		tst.b	(1,a2,d0.w)
		bne	@b
		move.b	d0,(a2)
		bsr	ana_cmdline

9:		rts

*----------------------------------------------------------
* コマンドライン・オプション解析
*----------------------------------------------------------
ana_cmdline:	tst.b	(a2)+
		beq	exit_chkcmd
get_next_cmd:	move.b	(a2)+,d0
		beq	exit_chkcmd
		cmpi.b	#$09,d0		* TAB
		beq	get_next_cmd
		cmpi.b	#$20,d0		* SPACE
		beq	get_next_cmd
		cmpi.b	#'-',d0		* '-'
		beq	get_next_cmd
		ori.b	#$20,d0
		cmpi.b	#'a',d0		* 'a'
		bne	@f
		st	(m_f,a6)
		st	(s_f,a6)
		st	(v_f,a6)
		st	(w_f,a6)
		st	(c_f,a6)
		st	(x_f,a6)
		st	(n_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'m',d0		* m
		bne	@f
		st	(m_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'s',d0		* s
		bne	@f
		st	(s_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'w',d0		* w
		bne	@f
		st	(w_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'v',d0		* v
		bne	@f
		st	(v_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'c',d0		* c
		bne	@f
		st	(c_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'x',d0		* x
		bne	@f
		st	(x_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'n',d0		* n
		bne	@f
		st	(n_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'z',d0		* z
		bne	@f
		st	(z_f,a6)
		bra	get_next_cmd

@@:		cmpi.b	#'q',d0		* q
		bne	@f
		st	(q_f,a6)
		bra	get_next_cmd

@@:		bsr	print_title
		bra	usage

exit_chkcmd:	rts

*----------------------------------------------------------
* パッチバージョン表示
*----------------------------------------------------------
print_version:	tst.b	(v_f,a6)
		beq	9f

		bsr	pline

		X030	_3_SYSVER
		move.l	d0,ver_msg
		move.l	a1,d0
		lea	(pat_addr,pc),a0
		bsr	bin2hex

		bsr	getmmus
		move.l	(tia,a6),d0
		lea	(srp_msg,pc),a0
		bsr	bin2hex
		move.l	(tib,a6),d0
		lea	(tib_msg,pc),a0
		bsr	bin2hex
		move.l	(tic,a6),d0
		lea	(tic_msg,pc),a0
		bsr	bin2hex

		suba.l	a1,a1
		IOCS	_B_SUPER
		move.l	d0,-(sp)
		
		movea.l	d5,a1
		move.l	(-4,a1),d0
		lea	(patchcrc_msg,pc),a0
		bsr	bin2hex
		
		lea	ROM_TOP,a1
		move.l	#$10000-4,d1
		tst.l	ROMDB_INST
		beq	@f
		lea	ROMDB_TOP,a1
		move.l	#(PMEM_MAX-ROMDB_TOP)-4,d1
@@:		bsr	crc_calc
		lea	(calccrc_msg,pc),a0
		bsr	bin2hex
		
		lea	(ptop_msg,pc),a1
		cmpi.l	#'X030',($00ff0000)
		beq	@f
		move.b	#'_',(a1)
		lea	(pat_addr,pc),a0
		moveq	#8-1,d0
1:		move.b	#'-',(a0)+
		dbra	d0,1b
		lea	(patchcrc_msg,pc),a0
		moveq	#8-1,d0
1:		move.b	#'-',(a0)+
		dbra	d0,1b
@@:		pea	(a1)
		DOS	_PRINT
		addq.l	#4,sp
		
		movea.l	(sp)+,a1
		IOCS	_B_SUPER
9:		rts

*----------------------------------------------------------
* マッピング表示
*----------------------------------------------------------
print_mapping:	tst.b	(m_f,a6)
		beq	9f

		pea	(addr_msg,pc)
		DOS	_PRINT
		addq.l	#4,sp
		suba.l	a1,a1			* 論理アドレス

mmap_loop:	lea	(logi_add_msg,pc),a0
		move.l	a1,d0
		bsr	bin2hex
		X030	_3_ADDRCNV		* 論理→物理変換
		cmpa.l	d0,a1			* 論理＝物理なら表示しない
		beq	8f
@@:		lea	(phyi_add_msg,pc),a0
		bsr	bin2hex
		pea	(a0)
		DOS	_PRINT
		moveq	#-1,d2
		X030	_3_MSTAT
		move.l	d0,d4
		bfextu	d4{31-7:1},d0
		move.l	(su_msg_table,pc,d0.w*4),(sp)
		DOS	_PRINT
		bfextu	d4{31-2:1},d0
		move.l	(wpwe_msg_table,pc,d0.w*4),(sp)
		DOS	_PRINT
		addq.l	#4,sp
		bsr	crlf
8:		adda.w	d6,a1
		cmpa.l	d5,a1
		bcs	mmap_loop

9:		rts

*----------------------------------------------------------
* 範囲表示サブルーチン
*  A1 論理アドレス
*  D7 対象ビット
*----------------------------------------------------------
area_sub:	move.l	d3,-(sp)
		clr.w	d0
		bset.l	d7,d0
		move.w	d0,d7
		moveq	#-1,d2			* 開始アドレス走査
		X030	_3_MSTAT
		move.w	d0,d3
		and.w	d7,d3
		movea.l	a1,a2			* A2 = 開始アドレス
		move.l	a1,d0
		lea	(sadd_msg,pc),a0
		pea	(a0)
		bsr	bin2hex
@@:		adda.w	d6,a1
		cmpa.l	d5,a1
		bcc	@f
		moveq	#-1,d2			* 終了アドレス走査
		X030	_3_MSTAT
		and.w	d7,d0
		eor.w	d3,d0
		beq	@b

@@:		move.l	a1,d0
		subq.l	#1,d0
		lea	(eadd_msg,pc),a0
		bsr	bin2hex
		move.l	a1,d0
		sub.l	a2,d0
		lea	(ladd_msg,pc),a0
		bsr	bin2hex
		DOS	_PRINT
		addq.l	#4,sp
		move.w	d3,d7
		move.l	(sp)+,d3
		rts

*----------------------------------------------------------
* スーパーバイザ領域表示
*----------------------------------------------------------
print_super:	tst.b	(s_f,a6)
		beq	9f

		pea	(psuper_msg,pc)
		DOS	_PRINT
		pea	(area_msg,pc)
		DOS	_PRINT
		addq.l	#8,sp
		suba.l	a1,a1			* 論理アドレス

super_loop:	moveq	#7,d7
		bsr	area_sub
		bfextu	d7{31-7:1},d0
		move.l	(su_msg_table,pc,d0.w*4),-(sp)
		DOS	_PRINT
		addq.l	#4,sp
		bsr	crlf
		cmpa.l	d5,a1
		bcs	super_loop

9:		rts

*----------------------------------------------------------
* ライトプロテクト領域表示
*----------------------------------------------------------
print_wp:	tst.b	(w_f,a6)
		beq	9f

		pea	(pwp_msg,pc)
		DOS	_PRINT
		pea	(area_msg,pc)
		DOS	_PRINT
		addq.l	#8,sp
		suba.l	a1,a1

wp_loop:	moveq	#2,d7
		bsr	area_sub
		bfextu	d7{31-2:1},d0
		move.l	(wpwe_msg_table,pc,d0.w*4),-(sp)
		DOS	_PRINT
		addq.l	#4,sp
		bsr	crlf
		cmpa.l	d5,a1
		bcs	wp_loop

9:		rts

*----------------------------------------------------------
* キャッシュモード表示
*----------------------------------------------------------
print_cache:	tst.b	(c_f,a6)
		beq	9f

		pea	(pcache_msg,pc)
		DOS	_PRINT
		pea	(area_msg,pc)
		DOS	_PRINT
		addq.l	#8,sp
		suba.l	a1,a1

cache_loop:	X030	_3_CASTAT
		move.w	d0,d3
		movea.l	a1,a2
		move.l	a1,d0
		lea	(sadd_msg,pc),a0
		pea	(a0)
		bsr	bin2hex
@@:		adda.w	d6,a1
		cmpa.l	d5,a1
		bcc	@f
		X030	_3_CASTAT
		eor.w	d3,d0
		beq	@b
@@:		move.l	a1,d0
		subq.l	#1,d0
		lea	(eadd_msg,pc),a0
		bsr	bin2hex
		move.l	a1,d0
		sub.l	a2,d0
		lea	(ladd_msg,pc),a0
		bsr	bin2hex
		DOS	_PRINT
		lsr.w	#1,d3
		move.l	(cache_msg_table,pc,d3.w*4),(sp)
		DOS	_PRINT
		addq.l	#4,sp
		bsr	crlf
		cmpa.l	d5,a1
		bcs	cache_loop

		bsr	pline
		moveq	#1,d1
		IOCS	_SYS_STAT
		move.w	d0,d1
		ror.w	#1,d0
		move.w	d0,d2
		pea	(ica_msg,pc)
		DOS	_PRINT
		andi.w	#%1,d1
		move.l	(on_off_table,pc,d1.w*4),(sp)
		DOS	_PRINT
		bsr	crlf
		pea	(dca_msg,pc)
		DOS	_PRINT
		andi.w	#%1,d2
		move.l	(on_off_table,pc,d2.w*4),(sp)
		DOS	_PRINT
		addq.l	#8,sp
		bsr	crlf

9:		rts

*----------------------------------------------------------
* トランスペアレント変換レジスタ表示
*----------------------------------------------------------
print_reg:	tst.b	(x_f,a6)
		beq	9f

		pea	(preg_msg,pc)
		DOS	_PRINT
		addq.l	#4,sp

		lea	(ttreg,a6),a2
		suba.l	a1,a1
		IOCS	_B_SUPER
		pmove.l	TT0,(a2)
		pmove.l	TT1,(4,a2)
		movea.l	d0,a1
		IOCS	_B_SUPER

		clr.l	d3
		lea	(xreg_msg,pc),a0
preg_loop:	move.l	(xreg_msg_table,pc,d3.w*4),-(sp)
		DOS	_PRINT
		pea	(-1,a0)		***
		move.l	(a2)+,d4
		move.l	d4,d0
		bsr	bin2hex
		DOS	_PRINT
		
		bfextu	d4{31-15:1},d1
		move.l	(endi_msg_table,pc,d1.w*4),(sp)
		DOS	_PRINT
		
		bfextu	d4{31-10:1},d1
		move.l	(cache_msg_table,pc,d1.w*4),(sp)
		DOS	_PRINT
		
		bfextu	d4{31-9:1},d1
		move.l	(rw_msg_table,pc,d1.w*4),(sp)
		DOS	_PRINT
		
		bfextu	d4{31-8:1},d1
		move.l	(rwm_msg_table,pc,d1.w*4),(sp)
		DOS	_PRINT

TT_disable:	addq.l	#8,sp
		bsr	crlf

		addq.l	#1,d3
		cmpi.b	#2,d3
		bne	preg_loop

9:		rts


*----------------------------------------------------------
* 不可視空間
*----------------------------------------------------------
print_nomap:	tst.b	(n_f,a6)
		beq	9f

		pea	(pnomap_msg,pc)
		DOS	_PRINT
		pea	(area_msg,pc)
		DOS	_PRINT
		addq.l	#8,sp

		clr.l	d2
		suba.l	a1,a1
		lea	(mapbuf,a6),a2
mk_map_table:	X030	_3_ADDRCNV
		bfextu	d0{0:32-13},d0
		st	(a2,d0.w)
		adda.w	d6,a1
		cmpa.l	d5,a1
		bcs	mk_map_table

		suba.l	a1,a1

pmap_loop:	cmpa.l	d5,a1
		bcc	9f
		tst.b	(a2)+		* top search
		bne	nonomap

		move.l	a1,d7
		move.l	a1,d0
		lea	(sadd_msg,pc),a0
		pea	(a0)
		bsr	bin2hex
@@:		cmpa.l	d5,a1
		bcc	@f
		adda.w	d6,a1
		tst.b	(a2)+		* bottom search
		beq	@b
@@:		move.l	a1,d0
		subq.l	#1,d0
		lea	(eadd_msg,pc),a0
		bsr	bin2hex
		move.l	a1,d0
		sub.l	d7,d0
		lea	(ladd_msg,pc),a0
		bsr	bin2hex
		DOS	_PRINT
		pea	(phyi_msg,pc)
		DOS	_PRINT
		addq.l	#8,sp
		bsr	crlf
		st	d2
nonomap:	adda.w	d6,a1
		cmpa.l	d5,a1
		bcs	pmap_loop
		tst.b	d2
		bne	@f
		pea	(nnmap_msg,pc)
		DOS	_PRINT
		addq.l	#4,sp
@@:
9:		rts

***********************************************************
* メイン
***********************************************************
main:		bsr	initialize

		X030	_3_SYSVER
		tst.l	d0
		bmi	no_030
		cmpi.l	#'0.40',d0
		bcs	no_030

		bsr	ana_cmdline
		bsr	getenv_option
		bsr	print_title
		bsr	chk_cmd

		bsr	print_version
		bsr	print_mapping
		bsr	print_super
		bsr	print_wp
		bsr	print_cache
		bsr	print_reg
		bsr	print_nomap

		bsr	pline
		DOS	_EXIT

*----------------------------------------------------------
* その他
*----------------------------------------------------------

xreg_msg_table:	dc.l	tt0_msg
		dc.l	tt1_msg
tt0_msg:	dc.b	'TT0 ',0
tt1_msg:	dc.b	'TT1 ',0

	.even
wpwe_msg_table:	dc.l	we_msg
		dc.l	wp_msg
we_msg:		dc.b	'Writeable      ',0
wp_msg:		dc.b	'WriteProtected ',0

	.even
su_msg_table:	dc.l	user_msg
		dc.l	super_msg
super_msg:	dc.b	'SUPER ',0
user_msg:	dc.b	'USER  ',0

	.even
cache_msg_table:
		dc.l	cachable_msg
		dc.l	noncache_msg
cachable_msg:	dc.b	'Cachable    ',0
noncache_msg:	dc.b	'Noncachable ',0

	.even
on_off_table:	dc.l	off_msg
		dc.l	on_msg
off_msg:	dc.b	'Off',0
on_msg:		dc.b	'On',0
ica_msg:	dc.b	'Instruction cache ... ',0
dca_msg:	dc.b	'Data cache .......... ',0

phyi_msg:	dc.b	'Physical address',0
logi_msg:	dc.b	'Logical address',0

	.even
endi_msg_table:	dc.l	disable_msg
		dc.l	enable_msg
disable_msg:	dc.b	'Disabled ',0
enable_msg:	dc.b	'Enabled  ',0

	.even
rw_msg_table:	dc.l	wr_msg
		dc.l	rd_msg
wr_msg:		dc.b	' W  ',0
rd_msg:		dc.b	' R  ',0
	.even
rwm_msg_table:	dc.l	use_msg
		dc.l	ign_msg
use_msg:	dc.b	'Used   ',0
ign_msg:	dc.b	'Ignored',0

ptop_msg:	dc.b	'030SYSpatch version '
ver_msg:	dc.b	'X.XX',13,10
		dc.b	'Root pointer: '
srp_msg:	dc.b	'00000000 '
		dc.b	'TIB:'
tib_msg:	dc.b	'00000000 '
		dc.b	'TIC:'
tic_msg:	dc.b	'00000000',13,10
		dc.b	'Patch area  : '
pat_addr:	dc.b	'00000000',13,10
		dc.b	'PATCH CRC   : '
patchcrc_msg:	dc.b	'00000000',13,10
		dc.b	'CALC CRC    : '
calccrc_msg:	dc.b	'00000000',13,10,0

addr_msg:	dc.b	'----------------------------------------------------------[MAPPING]-',13,10
		dc.b	'Physical   Logical   Status',13,10
		dc.b	'--------   --------  -----------------------------------------------',13,10,0

phyi_add_msg:	dc.b	'00000000 - '
logi_add_msg:	dc.b	'00000000  ',0

psuper_msg:	dc.b	'--------------------------------------------------[SUPERVISOR AREA]-',13,10,0
pwp_msg:	dc.b	'---------------------------------------------[WRITE PROTECTED AREA]-',13,10,0
pcache_msg:	dc.b	'-------------------------------------------------------[CACHE MODE]-',13,10,0
pnomap_msg:	dc.b	'---------------------------------------------------[INVISIBLE AREA]-',13,10,0
nnmap_msg:	dc.b	'No Invisible area.',13,10,0

area_msg:	dc.b	'  Head     Tail    Length   Status',13,10
		dc.b	'-------- -------- --------  ----------------------------------------',13,10,0

sadd_msg:	dc.b	'00000000 '
eadd_msg:	dc.b	'00000000 '
ladd_msg:	dc.b	'00000000  ',0

preg_msg:	dc.b	'------------------------------------------[TRANSPARENT TRANSLATION]-',13,10
		dc.b	'TT Regs.       Status   Cache       R/W RWM',13,10
		dc.b	'-------------  -------- ----------- --- ----------------------------',13,10,0

		dc.b	'='
xreg_msg:	dc.b	'00000000  ',0

	.bss

bss_top:	ds.b	BSS_SIZE

	.end	main
*
