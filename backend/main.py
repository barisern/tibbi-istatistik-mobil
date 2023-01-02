import pymysql
from app import app
from config import mysql
from flask import jsonify
from flask import flash, request, make_response
import traceback
import bcrypt
import jwt
from datetime import datetime, timedelta
from functools import wraps
import requests

def token_required(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        token = None
        # ensure the jwt-token is passed with the headers
        if 'x-access-token' in request.headers:
            token = request.headers['x-access-token']
        if not token: # throw error if no token provided
            return make_response(jsonify({"message": "A valid token is missing!"}), 401)
        try:
           # decode the token to obtain user public_id
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            conn = mysql.connect()
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            
            sqlQuery = "SELECT * FROM users WHERE username = %s LIMIT 1"
            bindData = (data["username"])
            cursor.execute(sqlQuery, bindData)
            
            current_user = cursor.fetchone()
        except:
            return make_response(jsonify({"message": "Invalid token!"}), 401)
         # Return the user information attached to the token
        return f(current_user, *args, **kwargs)
    return decorator

@app.route("/register", methods=['POST'])
def register():
    try:
        _json = request.json
        _username = _json['username']
        _password = _json['password']
        _email = _json['email']
        
        if _username and _password and _email and request.method == 'POST':
            conn = mysql.connect()
            cursor = conn.cursor(pymysql.cursors.DictCursor)
            
            salt = bcrypt.gensalt()
            hashed_password = bcrypt.hashpw(_password.encode('utf-8'), salt)
            
            sqlQuery = "INSERT INTO users (username, password, email) VALUES(%s, %s, %s)"
            bindData = (_username, hashed_password, _email)
            cursor.execute(sqlQuery, bindData)
            conn.commit()
            
            sqlQuery = "SELECT * FROM users WHERE username = %s LIMIT 1"
            bindData = (_username)
            cursor.execute(sqlQuery, bindData)
            
            account = cursor.fetchone()
            
            token = jwt.encode({
                'id': account['id'],
                'username': account['username'],
                'email': account['email'],
                'type': account['type'],
                'exp' : datetime.utcnow() + timedelta(minutes = 360)
            }, app.config['SECRET_KEY'])
            
            respone = jsonify({'status': 200, 'message': 'Kullanıcı oluşturuldu!', 'token': token})
            respone.status_code = 200
            cursor.close()
            conn.close()
            return respone
        else:
            return showMessage("POST isteği gönderin ve parametrelerinin dolu olduğundan emin olun.")
    except pymysql.err.IntegrityError as e:
        return showMessage("Bu kullanıcı adıyla önceden kayıt oluşturulmuş", 402)
    except KeyError as e:
        return showMessage("username, password ve email parametrelerinin tümünü gönderin!", 403)
    except Exception as e:
        traceback.print_exc()
        return showMessage("Exception on '/register' endpoint")

@app.route("/login", methods=['POST'])
def login():
    try:
        _json = request.json
        _username = _json['username']
        _password = _json['password']
        
        if _username and _password and request.method == 'POST':
            conn = mysql.connect()
            cursor = conn.cursor(pymysql.cursors.DictCursor)
      
            sqlQuery = "SELECT * FROM users WHERE username = %s LIMIT 1"
            bindData = (_username)
            cursor.execute(sqlQuery, bindData)
            
            account = cursor.fetchone()
            
            if not account:
                return showMessage("Wrong username or password", status_code=401) #no account
            
            if bcrypt.checkpw(_password.encode('utf-8'), account["password"].encode('utf-8')):
                token = jwt.encode({
                    'id': account['id'],
                    'username': account['username'],
                    'email': account['email'],
                    'type': account['type'],
                    'exp' : datetime.utcnow() + timedelta(minutes = 360)
                }, app.config['SECRET_KEY'])

                response = jsonify({'status': 200, 'message': 'Login Başarılı', 'token': token})
                response.status_code = 200
                cursor.close()
                conn.close()
                return response
            else:
                return showMessage("Wrong username or password", status_code=401) #wrong pass
        else:
            return showMessage("POST isteği gönderin ve parametrelerinin dolu olduğundan emin olun.")
    except pymysql.err.IntegrityError as e:
        return showMessage("Veritabanı hatası")
    except KeyError as e:
        return showMessage("username, password ve email parametrelerinin tümünü gönderin!")
    except Exception as e:
        traceback.print_exc()
        return showMessage("Exception on '/register' endpoint")        

@app.route("/saveForm", methods=["POST"])
@token_required
def saveForm(current_user):
    try:
        print(current_user["id"])
        _json = request.json
        
        _baslangic = _json['baslangic'][:-4]
        _bitis = _json['bitis'][:-4]
        _siddet = int(float(_json['siddet']))
        _bolge = _json['bolge']
        _ilac = _json['ilac']
        _belirti = _json['belirti']
        _detay = _json['detay']
        
        print(_json)
        
        if request.method == 'POST':
            conn = mysql.connect()
            cursor = conn.cursor(pymysql.cursors.DictCursor)
                
            sqlQuery = "INSERT INTO basagrisi (fk_UserId, baslangic, bitis, siddet, bolge, ilac, belirti, detay) VALUES(%s, %s, %s, %s, %s, %s, %s, %s)"
            bindData = (current_user["id"], _baslangic, _bitis, _siddet, _bolge, _ilac, _belirti, _detay)
            cursor.execute(sqlQuery, bindData)
            conn.commit()
                 
            respone = jsonify({'status': 200, 'message': 'Basagrisi oluşturuldu!'})
            respone.status_code = 200
            cursor.close()
            conn.close()
            
            requests.post("https://ntfy.sh/tibbi_stat", data=f"{current_user['username']} isimli hasta yeni bir baş ağrısı kaydı oluşturdu!\n\nBelirtilen Baş Ağrısı Şiddeti: {_siddet}/10".encode(encoding='utf-8'))
            return respone
        else:
            return showMessage("POST isteği gönderin ve parametrelerinin dolu olduğundan emin olun.")
    except pymysql.err.IntegrityError as e:
        return showMessage("Bu kullanıcı adıyla önceden kayıt oluşturulmuş", 402)
    except KeyError as e:
        return showMessage("username, password ve email parametrelerinin tümünü gönderin!", 403)
    except Exception as e:
        traceback.print_exc()
        return showMessage("Exception on '/saveForm' endpoint")

@app.route("/getForm", methods=["GET"])
@token_required
def getForm(current_user):
    try:    
        conn = mysql.connect()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
      
        if(str(current_user["type"]) == '0'):
            sqlQuery = "SELECT * FROM basagrisi INNER JOIN users ON `basagrisi`.fk_UserId=`users`.id WHERE fk_UserId=%s ORDER BY `basagrisi`.id DESC LIMIT 5; "
            bindData = (current_user["id"]) 
            cursor.execute(sqlQuery, bindData)
        else:
            sqlQuery = "SELECT * FROM basagrisi INNER JOIN users ON `basagrisi`.fk_UserId=`users`.id ORDER BY `basagrisi`.id DESC"
            cursor.execute(sqlQuery)
            
        data = []
        records = cursor.fetchall()
        for row in records:
            data.append({"id": row["id"], 'baslangic': row["baslangic"], 'bitis': row["bitis"], 'siddet': row["siddet"], 'bolge': row["bolge"], 'ilac': row["ilac"], 'belirti': row["belirti"], 'detay': row["detay"], 'username':row["username"]})
        
        response = jsonify(data)
        response.status_code = 200
        cursor.close()
        conn.close()
        return response
    except pymysql.err.IntegrityError as e:
        return showMessage("Veritabanı hatası")
    except KeyError as e:
        return showMessage("username, password ve email parametrelerinin tümünü gönderin!")
    except Exception as e:
        traceback.print_exc()
        return showMessage("Exception on '/register' endpoint")    

@app.errorhandler(400)
def showMessage(error="Error", status_code=400):
    message = {
        'status': status_code,
        'message': error,
    }
    respone = jsonify(message)
    respone.status_code = status_code
    return respone
    
if __name__ == "__main__":
    app.run()