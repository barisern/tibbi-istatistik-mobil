from app import app
from flaskext.mysql import MySQL

mysql = MySQL()
app.config['MYSQL_DATABASE_USER'] = 'root'
app.config['MYSQL_DATABASE_PASSWORD'] = ''
app.config['MYSQL_DATABASE_DB'] = 'tibbistat'
app.config['MYSQL_DATABASE_HOST'] = 'localhost'

app.config['SECRET_KEY'] = 'F7oJ3Y8YZtZwp6XK6Q1TOa1AUKoHgeYTePTGolx3nyNPkUn9xchhIbHeIKXTRSGI'
mysql.init_app(app)