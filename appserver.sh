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

mkdir -p /var/log/expense-logs
VALIDATE $? "Creating expense logs directory"

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default Nodejs version"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nodejs 20 version"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nodejs"

id expense # Before adding the user by name "expense" we are trying to get the ID for this user by command "id expense"

if [ $? -ne 0 ] # Obviously it wont be 0 as we havent added the user 
then
    useradd expense &>>$LOG_FILE_NAME # Now it will add user expense
    VALIDATE $? "Adding User Expense"
else
    echo -e "expense user already exists..... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading..backend code & copying to tmp directory"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "Going to app directory"

rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping backend code from tmp directory to our app directory"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies npm"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME

# The below 3 Commands are actually before mysql client installation steps in expense documentation of siva but dont know why he wrote in last steps

# systemctl daemon-reload &>>$LOG_FILE_NAME
# VALIDATE $? "backend daemon service is reloaded"

# systemctl enable backend &>>$LOG_FILE_NAME
# VALIDATE $? "Enabling backend service"

# systemctl start backend &>>$LOG_FILE_NAME
# VALIDATE $? "Starting backend service"

#Prepare MySQL Schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client at backend server"

mysql -h mysql.expenseslist.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions schema and tables"

# cd /app/schema/backend.sql &>>$LOG_FILE_NAME

# if [ $? -ne 0 ]
# then
#     echo "Backend Schema is available" &>>$LOG_FILE_NAME
#     mysql -h mysql.expenseslist.online -uroot -pExpenseApp@1 < /app/schema/backend.sql
#     VALIDATE $? "Backend Schema loaded"
# else
#     echo -e "Backend Schema already setup.....$Y SKIPPING $N"
# fi

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "backend daemon service is reloaded"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend service"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restarted backend service"



