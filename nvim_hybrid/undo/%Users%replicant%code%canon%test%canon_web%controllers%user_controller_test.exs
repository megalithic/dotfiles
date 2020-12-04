Vim�UnDo� @���rZ1.�� A�b���I%(�%u~   (   \    assert %{"id" => _id, "name" => "some name", "email" => "some@email"} = response["data"]            	       	   	   	    \:��    _�                             ����                                                                                                                                                                                                                                                                                                                                                             \:��     �                   �               5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \:��    �                  alias Toltec.Accounts�                  use ToltecWeb.ConnCase�                 )defmodule ToltecWeb.UserControllerTest do5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \:��     �         &      T  @create_attrs %{name: "some name", email: "some@email", password: "some password"}5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \:��     �         &      X  @create_attrs %{username: "some name", email: "some@email", password: "some password"}5�_�                       "    ����                                                                                                                                                                                                                                                                                                                                                             \:��     �         &      X  @create_attrs %{username: "some name", email: "some@email", password: "some password"}5�_�                           ����                                                                                                                                                                                                                                                                                                                                                             \:��     �         &      \    assert %{"id" => _id, "name" => "some name", "email" => "some@email"} = response["data"]5�_�      	                 .    ����                                                                                                                                                                                                                                                                                                                                                             \:��    �         &      `    assert %{"id" => _id, "username" => "some name", "email" => "some@email"} = response["data"]5�_�                  	      5    ����                                                                                                                                                                                                                                                                                                                                                             \:��    �   &            �   %   '          end�   $   &            end�   #   %              refute response["meta"]�   "   $          H    assert %{"email" => ["has already been taken"]} = response["errors"]�   !   #           �       "          '    response = json_response(conn, 422)�      !          >    conn = post(conn, user_path(conn, :create), @create_attrs)�                 '    Accounts.create_user(@create_attrs)�                G  test "doesn't create a user if email already taken", %{conn: conn} do�                 �                  end�                    refute response["meta"]�                M    assert %{"email" => _email, "password" => _password} = response["errors"]�                 �                '    response = json_response(conn, 422)�                ?    conn = post(conn, user_path(conn, :create), @invalid_attrs)�                M  test "doesn't create a user if incorrect params provided", %{conn: conn} do�                 �                  end�                2    assert %{"token" => _token} = response["meta"]�                /    refute Map.get(response["data"], :password)�                d    assert %{"id" => _id, "username" => "some username", "email" => "some@email"} = response["data"]�                 �                '    response = json_response(conn, 201)�                >    conn = post(conn, user_path(conn, :create), @create_attrs)�                S  test "creates a user when the required parameters are provided", %{conn: conn} do�                 �   
               end�   	             C    {:ok, conn: put_req_header(conn, "accept", "application/json")}�      
            setup %{conn: conn} do�      	           �                  @invalid_attrs %{}�                \  @create_attrs %{username: "some username", email: "some@email", password: "some password"}�                 �                  alias Canon.Accounts�                 �                  use CanonWeb.ConnCase�                 (defmodule CanonWeb.UserControllerTest do5�_�                            ����                                                                                                                                                                                                                                                                                                                                                             \:��     �          &      (username ToltecWeb.UserControllerTest do5��