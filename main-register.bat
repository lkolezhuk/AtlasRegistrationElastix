setlocal enabledelayedexpansion
mkdir output-lk
cd C:\Users\Admin\Documents\Education\MAIA-Spain\Segmentation\Atlas
SET referenceImage=0
SET iter=0
echo %referenceImage%
FOR /r %%i in (train-images\training-labels\*) DO (	
	SET trainlabels[!iter!]=%%i
    echo !trainlabels[%iter%]!
	SET /A iter=iter+1
)
SET iter=0
FOR /r %%i in (train-images\training-images\*) DO (
	echo %%i 
	SET /A iter=iter+1
	SET itername=!iter!leocarmen.mhd
	echo !itername!
	IF "!referenceImage!"=="0" (
		  SET referenceImage=%%i 
		  echo SetReferenceImage
	  ) ELSE (
		mkdir output-lk-!iter!
		mkdir output-labels-!iter!
		elastix -f !referenceImage! -m %%i -out output-lk-!iter! -p exampleinput/parameters_BSpline.txt >out.txt
		powershell "(Get-Content ./output-lk-!iter!/TransformParameters.0.txt) 
		| foreach-object { $_ -replace '(FinalBSplineInterpolationOrder 3)', 
		'FinalBSplineInterpolationOrder 0' } | Set-Content ./output-lk-!iter!/TransformParameters.0.txt"
		powershell "(Get-Content ./output-lk-!iter!/TransformParameters.0.txt) 
		| foreach-object { $_ -replace '(ResultImageFormat \"mhd\")', 'ResultImageFormat \"nii\"' } 
		| Set-Content ./output-lk-!iter!/TransformParameters.0.txt"
		transformix -in !trainlabels[%iter%]! -out output-labels-!iter! -tp output-lk-!iter!/TransformParameters.0.txt
	  )
)
echo %referenceImage%
@echo #Finshed


