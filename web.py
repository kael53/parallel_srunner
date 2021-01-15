from flask import Flask, request, render_template, abort
from subprocess import check_output, CalledProcessError, STDOUT

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route('/run', methods = [ 'POST' ])
def run():
    if not 'port[]' in request.form or not 'name[]' in request.form: abort(404)
    ports = request.form.getlist('port[]')
    names = request.form.getlist('name[]')
    file = open('instances.txt', 'w')
    for i in range(len(ports)):
        file.write(ports[i]+'\t'+names[i]+'\n')
    file.close()
    check_output(['screen', '-L', '-dmS', 'carla-run', './run.sh', 'instances.txt'])
    return ('', 204)

@app.route('/sigint', methods = [ 'POST' ])
def sigint():
    check_output(['./sigint.sh', 'carla-run'])
    return ('', 204)

@app.route('/clean', methods = [ 'POST' ])
def clean():
    if not 'port[]' in request.form or not 'name[]' in request.form: abort(404)
    ports = request.form.getlist('port[]')
    names = request.form.getlist('name[]')
    for i in range(len(ports)):
        try:
            check_output(['./clean.sh', ports[i], names[i]]).decode('utf-8').replace('\n', '<br>')
        except CalledProcessError as e:
            pass
    return ('', 204)

@app.route('/metrics', methods = [ 'POST' ])
def metrics():
    if not 'name' in request.form: abort(404)
    name = request.form['name'];
    images = check_output(['./metrics.sh', name+'.log', 'metrics/distances.py']).decode('ascii').split('\n')
    return f"<img src='data:image/png;base64,{images[0]}'/>\n<img src='data:image/png;base64,{images[1]}'/>"

@app.route('/status', methods = [ 'POST' ])
def status():
    if not 'port[]' in request.form: abort(404)
    ports = request.form.getlist('port[]')
    try:
        output = check_output(['screen', '-ls']).decode('utf-8')
    except CalledProcessError as e:
        output = e.output.decode('utf-8')
    response = []
    for i in range(len(ports)):
        if 'carla-simulator-'+ports[i] in output:
            if 'carla-autopilot-'+ports[i] in output:
                if 'carla-srunner-'+ports[i] in output:
                    # preparing
                    response.append('preparing')
                else:
                    # running
                    response.append('running')
            else:
                # starting
                response.append('starting')
        else:
            # finished
            response.append('finished')
    return ','.join(response)

@app.route("/stat")
def stat():
    gpustat = check_output(['gpustat', '-cp']).decode('utf-8').replace('\n','<br>')
    mem = check_output(['free', '-mh']).decode('utf-8').replace('\n','<br>')
    mpstat = check_output(['mpstat', '1', '1']).decode('utf-8').replace('\n','<br>')
    return '\n'.join([gpustat, mem, mpstat])

@app.route("/screenlog")
def screenlog():
    scripts = ['simulator','srunner','carlaviz','autopilot']
    port = request.args.get('port', default = 2000, type = int)
    contents = []
    for script in scripts:
        try:
            file = open('screenlog-carla-'+script+'-'+str(port), 'r')
            contents.append(str().join(file.readlines()[-44:]).replace('\n','<br>'))
            file.close()
        except:
            contents.append(str())
    return '\n'.join(contents)

if __name__ == '__main__':
	app.run(debug=True)
