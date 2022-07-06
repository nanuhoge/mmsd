;
;
	.include IOCSCALL.MAC
	.include DOSCALL.MAC

	.include SYSpatch.MAC

	.cpu	68000


	.text

main:
		lea	($10,a0),a0
		suba.l	a0,a1
		movem.l	a0/a1,-(sp)
		DOS	_SETBLOCK
		addq.l	#8,sp
		tst.l	d0
		bmi	setblock_err

		lea	($70,a0),a1
		lea	(name,pc),a3
@@:		move.b	(a1)+,(a3)+		; path
		bne	@b
		subq.l	#1,a3
		lea	($b4,a0),a1
@@:		move.b	(a1)+,(a3)+		; command name
		bne	@b

		lea	MPUTYPE,a1
		IOCS	_B_BPEEK
		cmpi.b	#3,d0
		beq	mmsd_exec
		cmpi.b	#4,d0
		bne	mpu_error

mmsd_exec:	subq.b	#2,d0
		lsl.w	#8,d0

		clr.l	-(sp)			; �����Ɠ�����
		pea	(a2)			; �����Ɠ����R�}���h���C��
		pea	(name,pc)		; �����Ɠ������O
		move.w	d0,-(sp)		; ������[����j
		DOS	_EXEC
		lea	(14,sp),sp
		tst.l	d0
		bpl	exit
exec_err:	pea	(2f,pc)
		bra	@f
setblock_err:	pea	(1f,pc)
		bra	@f
mpu_error:	pea	(9f,pc)
		moveq	#1,d0
@@:		DOS	_PRINT
		addq.l	#4,sp
exit:		move.w	d0,-(sp)
		DOS	_EXIT2

1:		dc.b	'_SETBLOCK ���s',13,10,0
2:		dc.b	'_EXEC ���s',13,10,0
9:		dc.b	'���݂̊��ł͎g���܂���',13,10,0


	.bss

name:		ds.b	1024

	.end	main
