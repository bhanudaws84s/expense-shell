#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R failure $N"
        exit 1
    else
        echo -e "$2 is $G success $N" 
    fi
}


CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R ERROR :: Please run this script with sudo access $N"
        exit 1
    fi

}

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nodejs 20"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding user"
else
    echo -e "User Expense already added $Y Skipping $N"
fi
mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading the backend code"

cd /app &>>$LOG_FILE_NAME

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping the code"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql server"

mysql -h sql.relationhospital.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Loading the Schema"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enable backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restart Backend"

