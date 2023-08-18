*** Settings ***
Documentation	Orders robots from RobotSpareBin Industries Inc.
...				Saves the order HTML receipt as a PDF file.
...				Saves the screenshot of the ordered robot.
...				Embeds the screenshot of the robot to the PDF receipt.
...				Creates ZIP archive of the receipts and the images.
...
...				Created for RPA Certification II (https://robocorp.com/docs/courses/build-a-robot/)
...
...				https://github.com/samporapeli/rpa-cert-II

Library				RPA.Archive
Library				RPA.Browser.Selenium	auto_close=${FALSE}
Library				RPA.FileSystem
Library				RPA.HTTP
Library				RPA.PDF
Library				RPA.Tables

*** Variables ***
${pdf_dir}	${OUTPUT_DIR}${/}receipts${/}
${img_dir}	${OUTPUT_DIR}${/}images${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
	Open the robot order website
	${orders}=	Get orders
	Loop through table	${orders}
	Create a ZIP archive of receipts
	[Teardown]	Close the browser and delete the directories

*** Keywords ***
Open the robot order website
	Open Available Browser	https://robotsparebinindustries.com/#/robot-order

Get orders
	Download
	...	https://robotsparebinindustries.com/orders.csv
	...	overwrite=True
	${table}=	Read table from CSV	orders.csv
	RETURN	${table}

Loop through table
	[Arguments]	${table}
	FOR	${row}	IN	@{table}
		Close the annoying modal
		Create the order for	${row}
		Click Button	id:order-another
	END

Close the annoying modal
	Click Button	css:.btn-danger

Create the order for
	[Arguments]	${row}
	Fill the form	${row}
	Preview the robot
	Wait Until Keyword Succeeds	100x	0 sec	Submit the order
	Save receipt

Fill the form
	[Arguments]	${row}
	Wait Until Page Contains Element	tag:form
	Select From List By Value	id:head					${row}[Head]
	Select Radio Button		 	body					${row}[Body]
	Input Text					css:input[type=number]	${row}[Legs]
	Input Text					id:address				${row}[Address]

Preview the robot
	Click Button	id:preview

Submit the order
	Click Button	id:order
	Wait Until Page Contains Element	id:receipt	timeout=0.1 sec

Save receipt
	Wait Until Element Is Visible	id:receipt
	${receipt_html}=	Get Element Attribute	id:receipt			outerHTML
	${receipt_id}=		Get Element Attribute	css:.badge-success	innerHTML
	Html To Pdf	${receipt_html}	${pdf_dir}${receipt_id}.pdf
	
	Save image	${receipt_id}

	Embed the robot screenshot to the receipt PDF file	${receipt_id}

Save image
	[Arguments]	${receipt_id}
	Wait Until Element Is Visible	id:robot-preview-image
	Wait Until Element Is Visible	css:img[alt='Head']
	Wait Until Element Is Visible	css:img[alt='Body']
	Wait Until Element Is Visible	css:img[alt='Legs']
	Capture Element Screenshot	id:robot-preview-image	${img_dir}${receipt_id}.png

Embed the robot screenshot to the receipt PDF file
	[Arguments]	${receipt_id}
	${image}=	Set Variable	${img_dir}${receipt_id}.png
	${pdf}=		Set Variable	${pdf_dir}${receipt_id}.pdf
	Add Watermark Image To PDF
	...	image_path=${image}
	...	source_path=${pdf}
	...	output_path=${pdf}

Create a ZIP archive of receipts
	${archive}=	Set Variable	${OUTPUT_DIR}${/}receipts.zip
	Archive Folder With Zip	${pdf_dir}	${archive}

Close the browser and delete the directories
	Remove Directory	${img_dir}	recursive=True
	Remove Directory	${pdf_dir}	recursive=True
	Close Browser
