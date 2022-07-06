# mmsd.x
040SYSpatch.x互換の拡張IOCS環境で現在のメモリ設定を表示します。

## 概要
040SYSpatch.xや030SYSpatch.xが動作している環境で、現在のMMU設定状況を表示します。  

対応する環境は次のとおりです。  
* 030SYSpatch.x（_30SYSpatch.x） v0.40 以降  
* 040SYSpatch.x（040SRAMpatch.r) v2.60 以降  

## 実行形式の作り方
68030と68040で同じような表示内容とオプションで別々の実行形式は面倒なので、1つの実行ファイルになるようバインドしています。  
mmsdx.sが68030と68040を振り分けをするプログラムで、それぞれの環境に合わせた実行形式を呼び出しています。

> as mmsdx.s  
> lk mmsdx.o  
> as mmsd030.s  
> lk mmsd030.o  
> as mmsd040.s  
> lk mmsd040.o  
> bind /o mmsd.x mmsdx.x mmsd030.x mmsd040.x  

手間いらずのリリース版のお持ち帰りがベターだとは思います。

## 表示例
オプション'a'を付けて実行した場合  

	Memory management status display v1.40 for 040SYSpatch.x
	---------------------------------------------------------------------
	040SYSpatch version 2.81
	Root pointer: 00BFFA00 TIB:00BFFC00 TIC:00004000
	Patch area  : 00BF0000
	PATCH CRC   : 3B2D25EE
	CALC CRC    : B6AFF006
	-----------------------------------------------------------[MAPPING]-
	Physical   Logical   Status
	--------   --------  ------------------------------------------------
	00BF0000 - 00FF0000  SUPER WriteProtected 
	00BF2000 - 00FF2000  SUPER WriteProtected 
	00BF4000 - 00FF4000  SUPER WriteProtected 
	00BF6000 - 00FF6000  SUPER WriteProtected 
	00BF8000 - 00FF8000  SUPER WriteProtected 
	00BFA000 - 00FFA000  SUPER WriteProtected 
	00BFC000 - 00FFC000  SUPER WriteProtected 
	00BFE000 - 00FFE000  SUPER WriteProtected 
	---------------------------------------------------[SUPERVISOR AREA]-
	  Head     Tail    Length   Status
	-------- -------- --------  -----------------------------------------
	00000000 000B1FFF 000B2000  SUPER 
	000B2000 00BEFFFF 00B3E000  USER  
	00BF0000 00EBFFFF 002D0000  SUPER 
	00EC0000 00ECFFFF 00010000  USER  
	00ED0000 00FFFFFF 00130000  SUPER 
	----------------------------------------------[WRITE PROTECTED AREA]-
	  Head     Tail    Length   Status
	-------- -------- --------  -----------------------------------------
	00000000 00003FFF 00004000  Writeable      
	00004000 00005FFF 00002000  WriteProtected 
	00006000 00BEFFFF 00BEA000  Writeable      
	00BF0000 00BFFFFF 00010000  WriteProtected 
	00C00000 00FEFFFF 003F0000  Writeable      
	00FF0000 00FFFFFF 00010000  WriteProtected 
	--------------------------------------------------------[CACHE MODE]-
	  Head     Tail    Length   Status
	-------- -------- --------  -----------------------------------------
	00000000 000C1FFF 000C2000  Cachable, Copyback
	000C2000 002D5FFF 00214000  Cachable, Writethrough
	002D6000 00BFFFFF 0092A000  Cachable, Copyback
	00C00000 00DFFFFF 00200000  Cachable, Writethrough
	00E00000 00E7FFFF 00080000  Noncachable
	00E80000 00EAFFFF 00030000  Noncachable, Serialized
	00EB0000 00EB7FFF 00008000  Noncachable
	00EB8000 00EBFFFF 00008000  Cachable, Writethrough
	00EC0000 00ECFFFF 00010000  Noncachable, Serialized
	00ED0000 00EDFFFF 00010000  Cachable, Writethrough
	00EE0000 00EFFFFF 00020000  Noncachable, Serialized
	00F00000 00FFFFFF 00100000  Cachable, Writethrough
	---------------------------------------------------------------------
	Instruction cache ... On
	Data cache .......... On
	-------------------------------------------[TRANSPARENT TRANSLATION]-
	TT Regs.       Status   FC2    WP             Cache Mode
	-------------  -------- ------ -------------- -----------------------
	ITT0=00000000  Disabled USER   Writeable      Cachable, Writethrough
	ITT1=00000000  Disabled USER   Writeable      Cachable, Writethrough
	DTT0=00000000  Disabled USER   Writeable      Cachable, Writethrough
	DTT1=00000000  Disabled USER   Writeable      Cachable, Writethrough
	----------------------------------------------------[INVISIBLE AREA]-
	  Head     Tail    Length   Status
	-------- -------- --------  -----------------------------------------
	00FF0000 00FFFFFF 00010000  Physical address
	---------------------------------------------------------------------
