SUBROUTINE climo(STATUS)

!Till: modified allocation of input buffer that led to problem when input files contained different number of columns
!2010-04-26

!Till: modified allocation of input buffer that led to problem under linux
!2008-08-15

!Till: corrrected error messaging and loading in loading rain_hourly.dat when obsolete subbasins were present
!2008-08-11

!Till: removed reference to unallocated vars that led to crash in linux
!2008-04-09

!Till: positioning of file pointer within rain_hourly.dat may have been faulty
!rain_daily.dat is no longer needed in hourly version
!2008-10-1

!Till: improved error checking and messaging
!2008-10-1

!Till: improved error checking and messaging
!2008-08-12

!Till: corrected imprecision in positioning the file pointer within input files, if the column number was less than number of subbasins (data_seek)
!2008-07-03

!Till: reads inputfiles regardless of column order, excess columns are ignored (hourly version still pending)
! 2008-02-06

!Till: open input files as shared and read-only (enables run if still opened by Excel)
! 2008-01-25

!Till: handle climate input files with the subbasins not in the order of hymo.dat
! 2008-01-23

! Till: open files when STATUS==0
!	seek  correct file position when startmonth /= 1
! 2007-05-07

! Till: initialized temp, rhum, rad, precip with plausible values to allow check_climate
! 2006-08-02

! Till: added CALL to check_climate	(simple check of validity of climate data)
! 2006-03-16

! Code converted using TO_F90 by Alan Miller
! Date: 2005-06-30  Time: 13:45:46
use climo_h
use common_h
use hymo_h
use params_h
use time_h
use utils_h
IMPLICIT NONE


INTEGER, INTENT(IN OUT)                  :: STATUS

! status of call (0=initialization, 1=start of year,
!                 2=daily step,     3=end of year)

! counters
INTEGER :: i,j,k,id,n,iostat !,imun,imeso,istate,z,mm,bat,make,testi,dall ,idummy 
REAL :: dummy !,dif,difc


! grids of monthly mean shortwave radiation (W/m^2)
!REAL :: radigrid(14,18,12)
!REAL :: radi1,radi2
!REAL :: xdum(48)
!INTEGER :: idum(2)
!REAL :: inp,test,calibdtemp
!INTEGER :: inpd(3)
!REAL :: dummr
!INTEGER :: dummi !,ncelltem,doone, loop
!CHARACTER :: dummc
CHARACTER (len=50) :: dumstr
INTEGER   :: columnheader(1000)	!Till: for storing column headings of input files
!INTEGER :: nbrezgmun(subasin),idezgmun(50,subasin)
CHARACTER (LEN=8000) :: linedummy	!Till: dummy for reading input header	!ii: allocate dynamically
integer, pointer, save :: corr_column_temp(:),corr_column_rhum(:),corr_column_rad(:),corr_column_precip(:) !Till: hold corresponding columns of input files to be related to internal numbering of subbasins 
INTEGER,save  :: no_columns(5)=0		!number of columns of input files for the 5 climate input files
REAL,allocatable,save :: inputbuffer(:,:)				!Till: for buffering input data 
!REAL,allocatable,save :: inputbuffer2(:,:)				!Till: for buffering input data 


!CCCCCCCCCCCCCCCCCCCC MODULE CODE CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
IF (STATUS == 0) THEN

 IF (dohour) THEN
	dumstr='rain_hourly.dat'	!Till: load hourly rainfall
  else
	dumstr='rain_daily.dat'	!Till: load daily rainfall
 END IF
  

!reads in daily temperature, humiditiy, short wave radiation and precipitation for simulation period
!  OPEN(81,FILE=pfadp(1:pfadj)// '/Time_series/temperature.dat',STATUS='old',action='read',readonly,shared)
!  OPEN(82,FILE=pfadp(1:pfadj)// '/Time_series/humidity.dat',STATUS='old',action='read',readonly,shared)
!  OPEN(83,FILE=pfadp(1:pfadj)// '/Time_series/radiation.dat',STATUS='old',action='read',readonly,shared)
!  OPEN(84,FILE=pfadp(1:pfadj)// dumstr,STATUS='old',action='read',readonly,shared)

  OPEN(81,FILE=pfadp(1:pfadj)// '/Time_series/temperature.dat',STATUS='old',action='read')
  OPEN(82,FILE=pfadp(1:pfadj)// '/Time_series/humidity.dat',STATUS='old',action='read')
  OPEN(83,FILE=pfadp(1:pfadj)// '/Time_series/radiation.dat',STATUS='old',action='read')
  OPEN(84,FILE=pfadp(1:pfadj)// '/Time_series/'//dumstr,STATUS='old',action='read')


  READ(81,*); READ (82,*); READ (83,*); READ (84,*)
  READ(81,*); READ (82,*); READ (83,*); READ (84,*)
!Checks if sub-basin data are in the correct order (as given for the MAP-IDs in hymo.dat)


  READ(81,'(a)') linedummy
  columnheader=0
  no_columns(1)=GetNumberOfSubstrings(linedummy)-2	!Till: count number of columns
  READ (linedummy,*) dummy, dummy, (columnheader(i), i=1,no_columns(1))	!Till: extract column headers
  corr_column_temp=>set_corr_column(columnheader, 'temperature.dat')
  
  READ(82,'(a)') linedummy
  columnheader=0
  no_columns(2)=GetNumberOfSubstrings(linedummy)-2	!Till: count number of columns
  READ (linedummy,*) dummy, dummy, (columnheader(i), i=1,no_columns(2))	!Till: extract column headers
  corr_column_rhum=>set_corr_column(columnheader,'humidity.dat')

  READ(83,'(a)') linedummy
  columnheader=0
  no_columns(3)=GetNumberOfSubstrings(linedummy)-2	!Till: count number of columns
  READ (linedummy,*) dummy, dummy, (columnheader(i), i=1,no_columns(3))	!Till: extract column headers
  corr_column_rad=> set_corr_column(columnheader,'radiation.dat')

  READ(84,'(a)') linedummy
  columnheader=0
  no_columns(4)=GetNumberOfSubstrings(linedummy)-2	!Till: count number of columns
  READ (linedummy,*) dummy, dummy, (columnheader(i), i=1,no_columns(4))	!Till: extract column headers
  corr_column_precip=>set_corr_column(columnheader,dumstr)
	
	
  do i=1,subasin
	if (associated(corr_column_pre_subbas_outflow) ) then
		if (corr_column_pre_subbas_outflow(i)>0) then		!Till: assign dummy climate data for those subbasins that are prespecified
			corr_column_temp(i)=1
			corr_column_rhum(i)=1
			corr_column_rad(i)=1
			corr_column_precip(i)=1
		end if
	end if
	
	if (1.0*corr_column_temp(i)*corr_column_rhum(i)*corr_column_rad(i)*corr_column_precip(i)==0) then	!check completeness
		write(*,*)'climate data is incomplete for subbasin',id_subbas_extern(i)
	end if
  end do


  allocate(inputbuffer(366*nt,maxval(no_columns)))		!Till: prepare input buffer to fit the data
  
 !set internal filepointers to correct line (simulation start)
  call date_seek(81,tstart,mstart,'temperature.dat')
  call date_seek(82,tstart,mstart,'humidity.dat')
  call date_seek(83,tstart,mstart,'radiation.dat')
  call date_seek(84,tstart,mstart,dumstr)	
  
  
END IF

! -------------------------------------------------------------
IF (STATUS == 1) THEN

!Reads in daily time series for temperature, humidity, radiation, rainfall
!
 !loop=dtot-dayyear
 !DO id=1,loop
 ! READ(81,*) dummy
 ! READ(82,*) dummy
 ! READ(83,*) dummy
 ! READ(84,*) dummy
 !END DO

 temp=0
 rhum=5
 rad=30
 precip=50
 
 READ(81,*,IOSTAT=iostat) (dummy,dummy,(inputbuffer (id,i),i=1,no_columns(1)),id=1,dayyear)		!Till: faster than using loop
 temp(1:dayyear,1:subasin)= inputbuffer(1:dayyear,corr_column_temp)	!Till: rearrange column order to match order of hymo.dat
 if (iostat/=0) then	!
		write(*,'(A,i3,a,i0)')'ERROR: input file format error in temperature.dat'
		stop
 end if

 READ(82,*,IOSTAT=iostat) (dummy,dummy,(inputbuffer (id,i),i=1,no_columns(2)),id=1,dayyear)		!Till: faster than using loop
 rhum(1:dayyear,1:subasin)= inputbuffer (1:dayyear,corr_column_rhum)	!Till: rearrange column order to match order of hymo.dat
 if (iostat/=0) then	!
		write(*,'(A,i3,a,i0)')'ERROR: input file format error in humidity.dat'
		stop
 end if

 READ(83,*,IOSTAT=iostat) (dummy,dummy,(inputbuffer (id,i),i=1,no_columns(3)),id=1,dayyear)		!Till: faster than using loop
 rad(1:dayyear,1:subasin)= inputbuffer (1:dayyear,corr_column_rad)	!Till: rearrange column order to match order of hymo.dat 
 if (iostat/=0) then	!
		write(*,'(A,i3,a,i0)')'ERROR: input file format error in radiation.dat'
		stop
 end if


	IF (.NOT. dohour) THEN
		READ(84,*,IOSTAT=iostat) (dummy,dummy,(inputbuffer (id,i),i=1,no_columns(4)),id=1,dayyear)		!Till: faster than using loop
		precip(:,1:subasin)= inputbuffer (:,corr_column_precip)	!Till: rearrange column order to match order of hymo.dat	 
	else 
		!read hourly rainfall data
		!for hourly version - program still needs the daily data as well, but this is computed internally below

			preciph(:,:)=-1	!hourly precip

		READ (84,*,IOSTAT=iostat) ((n,k,(inputbuffer((i-1)*24+j,id),id=1,no_columns(4)),j=1,nt),i=1,dayyear)
		preciph(:,1:subasin)= inputbuffer (:,corr_column_precip)	!Till: rearrange column order to match order of hymo.dat	 


		if (t/=tstop) then	!Till: lookup the day of month that should have been read last
			j=daymon(12)
		else
			j=daymon(mstop) 
			IF (mstop==2 .AND. MOD(t,4) == 0) j=29	!leap year
		end if
		if (n/1000000/=j) then
			write(*,'(a,i0)')'Error in date numbering/formatting of rain_hourly.dat, year ',t
			stop
		end if
			 
		!loop over all days of year and sum up daily precip
		DO i=1,dayyear		
			precip(i,:)=sum(preciph((i-1)*nt+1:i*nt,:),dim=1) 
		END DO

	END IF
	if (iostat/=0) then	!
		write(*,'(A,i3,a,i0)')'ERROR: input file format error in ',dumstr
		stop
    end if


wind=1	!Till: currently not read from input file (assumed constant)


CALL check_climate	!check validity of climate data

CALL petcalc		!Till: compute potential evaporation for each day and subbasin

!  end if status loop
END IF


! --------------------------------------------------------------------
!** At the end of the year
IF (STATUS == 3) THEN
  
!** Obtain monthly and annual values
  
!        call total  (precip,annprc ,monprc ,1.)
!        call total  (pet   ,annpet ,monpet ,1.)
!        call total  (petm   ,annpetm ,monpetm ,1.)
!        call average(temp  ,anntmp ,montmp ,1.)
!        call average(rhum  ,annrhum,monrhum,1.)
!        call average(rad   ,annrad ,monrad ,1.)
!        call average(wind  ,annwind,monwind,1.)
  
!        make=1
!        if (make.eq.1) then
!        open(11,file=pfadn(1:pfadi)//'monprc.out',status='old'
!     .       ,position='append')
  
!        do mm=1,subasin
!        do j=1,12
!          write(11,'(f7.1)') monprc(j,mm)
!        enddo
!        enddo
!        close(11)
!        endif
  
  
  
!        make=1
!        if (make.eq.1) then
!        open(11,file=pfadn(1:pfadi)//'monpet.out',status='old'
!     .       ,position='append'  )
  
!        do mm=1,subasin
!        do j=1,12
!          write(11,'(f7.1)') monpet(j,mm)
!        enddo
!        enddo
!        close(11)
  
!        open(11,file=pfadn(1:pfadi)//'monpetm.out',status='old'
!     .       ,position='append'  )
!        do mm=1,nmunalt
!        do j=1,12
!          write(11,'(f7.1)') monpetm(j,mm)
!        enddo
!        enddo
!        close(11)
!        endif
  
!        make=1
!        if (make.eq.1) then
!        open(11,file=pfadn(1:pfadi)//'annprc.out',status='old'
!     .       ,position='append'  )
  
!        do mm=1,subasin
!          write(11,'(f7.1)') annprc(mm)
!        enddo
!        close(11)
  
!        open(11,file=pfadn(1:pfadi)//'annpet.out',status='old'
!     .       ,position='append'  )
!        do mm=1,subasin
!          write(11,'(f7.1)') annpet(mm)
!        enddo
!        close(11)
!        endif
  
!        do imun=1,subasin
!          aveprc(imun) = aveprc(imun) + annprc(imun)/years
!          avetmp(imun) = avetmp(imun) + anntmp(imun)/years
!          avepet(imun) = avepet(imun) + annpet(imun)/years
!          averhum(imun) = averhum(imun) + annrhum(imun)/years
!        enddo
  
!        if (t .eq. tstop) then
!          open(11,file=pfadn(1:pfadi)//'climave.dat',status='replace')
!          do imun=1,subasin
!            write(11,'(4f9.1)')aveprc(imun),avetmp(imun),
!     .                 avepet(imun),averhum(imun)
!          enddo
!          close(11)
!        endif
  
END IF

RETURN



contains
	FUNCTION set_corr_column(input_header,inputfile_name)
	!provide "pointer" to to match order of subbasins to that in hymo.dat
	use params_h
	use hymo_h

	implicit none
		integer, pointer :: set_corr_column(:)
		INTEGER, INTENT(IN)                  :: input_header(:)	!order of subbasins in input file
		character(len=*), INTENT(IN)                  :: inputfile_name	!name of input file
		integer	:: i,j,k
		
		allocate(set_corr_column(subasin))	
		set_corr_column=0
		
		DO i=1,subasin
			 DO j=1,size(input_header)
				IF(input_header(j) == id_subbas_extern(i)) THEN
					set_corr_column(i)= j	!Till: for each subbasin, find position of corresponding column in input file
					exit
				END IF

				if (associated(corr_column_pre_subbas_outflow)) then
					k=which1(corr_column_pre_subbas_outflow==id_subbas_extern(i))
				else
					k=0
				end if

				if  (j==size(input_header) .AND. (k==0)) then
					WRITE(*,'(a,i0,a,a,a)') 'ERROR: Sub-basin-ID ',id_subbas_extern(i),' not found in ',inputfile_name,', quitting.'
					stop
				end if
				
			END DO

		END DO
	END FUNCTION set_corr_column



END SUBROUTINE climo



SUBROUTINE set_corr_column2(index_array,input_header,inputfile_name)
!provide "pointer" to to match order of subbasins to that in hymo.dat
use params_h
use hymo_h

implicit none
	INTEGER, INTENT(IN)                  :: input_header(subasin)	!order of subbasins in input file
	character(len=*), INTENT(IN)                  :: inputfile_name	!name of input file
	integer	:: i,j
	integer, intent(OUT) :: index_array(subasin)

	DO i=1,subasin
		 DO j=1,subasin
			IF(input_header(j) == id_subbas_extern(i)) THEN
				index_array(i)= j	!Till: for each subbasin, find position of corresponding column in input file
				exit
			END IF

			if  (j==subasin) then
				WRITE(*,'(a,i0,a,a,a)') 'ERROR: Sub-basin-ID ',id_subbas_extern(i),' not found in ',inputfile_name,', quitting.'
				stop
			end if
			
		END DO
	END DO
END SUBROUTINE set_corr_column2






SUBROUTINE date_seek(fid,tstart,mstart,filename)
!move file pointer to position corresponding to start of simulation period

use params_h

implicit none
	INTEGER, INTENT(IN)                  :: fid	!file handle
	INTEGER, INTENT(IN)                  :: tstart, mstart	!start year, start month of simulation
	CHARACTER(LEN=*),  INTENT(IN)                  :: filename	!name of file to produce meaningful error message

	INTEGER                  :: date_num, dum,iostat	!dummy values
	CHARACTER                  :: temp2	!dummy 

	READ(fid,*,IOSTAT=iostat) date_num,dum,temp2
	do while ((mod(date_num,1000000)/=mstart*10000+tstart) .AND. (iostat==0))
		READ(fid,*,IOSTAT=iostat) date_num,dum,temp2		!advance until start month is reached
	end do
	
	if ((iostat/=0) .OR. (floor(date_num/1000000.0)/=1)) then	!abort if start month does not start with its first day
		write(*,'(A,i3,a,i0)')'ABORTED: input file '//filename//' does not contain first day of simulation start month',mstart,'/',tstart
		stop
	end if
	
	BACKSPACE (fid)		!rewind line just read


END SUBROUTINE date_seek





