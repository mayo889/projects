import time
import requests
import networkx as nx
from tqdm import tqdm
from passwords import TOKEN, MY_ID, BAD_USERS


def request(method, params):
    url = f'https://api.vk.com/method/{method}'
    params['access_token'] = TOKEN
    params['v'] = '5.131'
    r = requests.get(url, params=params)
    return r.json()['response']


def transform_user_info(info):
    return {
            'name': f"{info['first_name']} {info['last_name']}",
            'id': int(info['id']),
            'sex': int(info['sex']),
            'city': info['city']['title'] if info.get('city') else '',
            'country': info['country']['title'] if info.get('country') else '',
            'university': info['university_name'] if info.get('university_name') else ''
        }


def get_user_friends(user_id):
    fields = ['city', 'country', 'education', 'home_town', 'sex']
    params = {'user_id': user_id,
              'fields': ','.join(fields),
              }
    r = request('friends.get', params)
    return [transform_user_info(user) for user in r['items']]


def generate_graph_only_my_friends(graph_name):
    attrs = {}
    G = nx.Graph()
    my_friends = get_user_friends(MY_ID)
    my_friends_id = set([friend['id'] for friend in my_friends])

    for u in tqdm(my_friends):
        if u['id'] in BAD_USERS:
            continue
        time.sleep(0.2)
        attrs[u['id']] = u
        try:
            cur_friends = get_user_friends(u['id'])
            for v in cur_friends:
                if v['id'] in my_friends_id:
                    G.add_edge(u['id'], v['id'])
        except:
            # Исключение выпадает на друзьях,
            # которые удалили аккаунт или временно заблокированы
            print(u)

    nx.set_node_attributes(G, attrs)

    nx.write_graphml(G, f'{graph_name}.graphml', encoding='utf-8')


if __name__ == "__main__":
    generate_graph_only_my_friends('test')
