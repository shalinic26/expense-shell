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


VALIDATE(){                 # This function needs previous command's (dnf install mysql -y) exit status as Input
    if [ $1 -ne 0 ]             # -> $1 will have exit status of previous command i.e. dnf install mysql -y is previous command
    then
        echo -e "$2.....$R FAILURE $N"
        exit 1
    else
        echo -e "$2......$G SUCCESS $N"
    fi
}


CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
    echo "ERROR: You must have sudo access to execute this script"
    exit 1 # other than 0
    fi
}

mkdir -p $LOGS_FOLDER
VALIDATE $? "Creating expense logs directory"

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nginx Server"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nginx Server"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting Nginx Server"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing existing nginx version of code from html directory"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading..frontend code & copying to tmp directory"

cd /usr/share/nginx/html &>>$LOG_FILE_NAME
VALIDATE $? "Going to html directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping frontend code from tmp directory to our html directory"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting Nginx Service"
